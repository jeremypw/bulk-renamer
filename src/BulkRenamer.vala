/*
 * Copyright (C) 2010-2017  Vartan Belavejian
 * Copyright (C) 2019      Jeremy Wootten
 *
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Authors:
 *  Vartan Belavejian <https://github.com/VartanBelavejian>
 *  Jeremy Wootten <jeremywootten@gmail.com>
 *
*/

public class Renamer : Gtk.Grid {
    private Gee.HashMap<string, File> file_map;
    private Gee.HashMap<string, FileInfo> file_info_map;
    private Gee.ArrayList<Modifier> modifier_chain;
    private Gee.LinkedList<Gee.HashMap<string, string>> undo_stack;

    private Gtk.Grid modifier_grid;
    private Gtk.ListBox modifier_listbox;

    private Gtk.TreeView old_file_names;
    private Gtk.TreeView new_file_names;
    private Gtk.ListStore old_list;
    private Gtk.ListStore new_list;

    private Gtk.Entry base_name_entry;
    private Gtk.ComboBoxText base_name_combo;
    private Gtk.Switch sort_type_switch;
    private Gtk.ComboBoxText sort_by_combo;

    private Mutex info_map_mutex;

    private int number_of_files = 0;

    public bool can_rename { get; set; default = false; }

    public bool can_undo { get; set; }
    public string directory { get; private set; default = ""; }

    public Renamer (File[]? files = null) {
        if (files != null) {
            add_files (files);
        }
    }

    construct {
        vexpand = true;

        info_map_mutex = Mutex ();

        can_rename = false;
        orientation = Gtk.Orientation.VERTICAL;
        directory = "";

        file_map = new Gee.HashMap<string, File> ();
        file_info_map = new Gee.HashMap<string, FileInfo> ();
        modifier_chain = new Gee.ArrayList<Modifier> ();
        undo_stack = new Gee.LinkedList<Gee.HashMap<string, string>> ();

        var base_name_label = new Granite.HeaderLabel (_("Base"));
        base_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        base_name_combo = new Gtk.ComboBoxText ();
        base_name_combo.valign = Gtk.Align.CENTER;
        base_name_combo.insert (RenameBase.ORIGINAL, "ORIGINAL", RenameBase.ORIGINAL.to_string ());
        base_name_combo.insert (RenameBase.CUSTOM, "CUSTOM", RenameBase.CUSTOM.to_string ());

        base_name_entry = new Gtk.Entry ();
        base_name_entry.placeholder_text = _("Enter naming scheme");
        base_name_entry.hexpand = false;
        base_name_entry.set_max_width_chars (64);
        base_name_entry.valign = Gtk.Align.CENTER;

        var base_name_entry_revealer = new Gtk.Revealer ();
        base_name_entry_revealer.add (base_name_entry);
        base_name_entry_revealer.vexpand = false;
        var sort_by_label = new Gtk.Label (_("Sort by:"));
        sort_by_combo = new Gtk.ComboBoxText ();
        sort_by_combo.valign = Gtk.Align.CENTER;
        sort_by_combo.margin = 3;
        sort_by_combo.insert (RenameSortBy.NAME, "NAME", RenameSortBy.NAME.to_string ());
        sort_by_combo.insert (RenameSortBy.CREATED, "CREATED", RenameSortBy.CREATED.to_string ());
        sort_by_combo.insert (RenameSortBy.MODIFIED, "MODIFIED", RenameSortBy.MODIFIED.to_string ());
        sort_by_combo.set_active (RenameSortBy.NAME);

        var sort_by_grid = new Gtk.Grid ();
        sort_by_grid.orientation = Gtk.Orientation.HORIZONTAL;
        sort_by_grid.column_spacing = 6;
        sort_by_grid.add (sort_by_label);
        sort_by_grid.add (sort_by_combo);

        var sort_type_label = new Gtk.Label (_("Reverse"));
        sort_type_switch = new Gtk.Switch ();
        sort_type_switch.valign = Gtk.Align.CENTER;

        var sort_type_grid = new Gtk.Grid ();
        sort_type_grid.margin = 3;
        sort_type_grid.orientation = Gtk.Orientation.HORIZONTAL;
        sort_type_grid.column_spacing = 6;
        sort_type_grid.add (sort_type_switch);
        sort_type_grid.add (sort_type_label);

        var controls_grid = new Gtk.Grid ();
        controls_grid.orientation = Gtk.Orientation.HORIZONTAL;
        controls_grid.column_spacing = 12;
        controls_grid.margin_bottom = 12;

        controls_grid.attach (base_name_label, 0, 0, 2, 1);
        controls_grid.attach (base_name_combo, 0, 1, 1, 1);
        controls_grid.attach (base_name_entry_revealer, 1, 1, 1, 1);

        var modifiers_label = new Granite.HeaderLabel (_("Modifiers"));
        modifiers_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        modifier_listbox = new Gtk.ListBox ();

        var add_button = new Gtk.MenuButton ();
        add_button.valign = Gtk.Align.CENTER;
        add_button.image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        add_button.tooltip_text = _("Install language");
        add_button.sensitive = true;

        var action_bar = new Gtk.ActionBar ();
        action_bar.margin_top = 12;
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.pack_start (add_button);

        modifier_grid = new Gtk.Grid ();
        modifier_grid.orientation = Gtk.Orientation.VERTICAL;
        modifier_grid.margin_bottom = 12;
        modifier_grid.row_spacing = 0;
        modifier_grid.add (modifiers_label);
        modifier_grid.add (modifier_listbox);
        modifier_grid.add (action_bar);

        var cell = new Gtk.CellRendererText ();
        cell.ellipsize = Pango.EllipsizeMode.END;
        cell.wrap_mode = Pango.WrapMode.CHAR;
        cell.width_chars = 64;

        old_list = new Gtk.ListStore (1, typeof (string));
        old_list.set_default_sort_func (old_list_sorter);
        old_list.set_sort_column_id (Gtk.SortColumn.DEFAULT, Gtk.SortType.ASCENDING);

        old_file_names = new Gtk.TreeView.with_model (old_list);
        old_file_names.insert_column_with_attributes (-1, "ORIGINAL", cell, "text", 0);

        old_file_names.hexpand = true;
        old_file_names.set_headers_visible (false);

        var old_files_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        old_files_header.hexpand = true;
        var original_label = new Granite.HeaderLabel (_("Original Names"));
        original_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        original_label.valign = Gtk.Align.CENTER;
        old_files_header.add (original_label);
        sort_by_grid.halign = Gtk.Align.END;
        sort_by_grid.valign = Gtk.Align.CENTER;
        sort_type_grid.halign = Gtk.Align.END;
        sort_type_grid.valign = Gtk.Align.CENTER;
        old_files_header.pack_end (sort_type_grid, false, false, 6);
        old_files_header.pack_end (sort_by_grid, false, false, 6);

        var old_scrolled_window = new Gtk.ScrolledWindow (null, null);
        old_scrolled_window.hexpand = true;
        old_scrolled_window.add (old_file_names);
        old_scrolled_window.set_min_content_height (300);
        old_scrolled_window.set_max_content_height (2000);

        var vadj = old_scrolled_window.get_vadjustment ();

        var old_files_grid = new Gtk.Grid ();
        old_files_grid.valign = Gtk.Align.START;
        old_files_grid.orientation = Gtk.Orientation.VERTICAL;
        old_files_grid.add (old_files_header);
        old_files_grid.add (old_scrolled_window);

        var toggle = new Gtk.CellRendererToggle ();
        toggle.indicator_size = 9;
        toggle.xalign = 1.0f;
        var new_cell = new Gtk.CellRendererText ();
        new_cell.ellipsize = Pango.EllipsizeMode.END;
        new_cell.wrap_mode = Pango.WrapMode.CHAR;
        new_cell.width_chars = 64;
        new_list = new Gtk.ListStore (2, typeof (string), typeof (bool));
        new_file_names = new Gtk.TreeView.with_model (new_list);
        var text_col = new_file_names.insert_column_with_attributes (-1,"NEW", new_cell, "text", 0, "sensitive", 1);
        new_file_names.insert_column_with_attributes (-1, "VALID", toggle, "active", 1, "visible", 1);
        new_file_names.headers_visible = false;

        var new_scrolled_window = new Gtk.ScrolledWindow (null, null);
        new_scrolled_window.hexpand = true;
        new_scrolled_window.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.EXTERNAL);
        new_scrolled_window.set_vadjustment (vadj);
        new_scrolled_window.add (new_file_names);
        new_scrolled_window.set_min_content_height (300);
        new_scrolled_window.set_max_content_height (2000);
        new_scrolled_window.set_overlay_scrolling (true);

        var new_files_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        var new_label = new Granite.HeaderLabel (_("New Names"));
        new_label.get_style_context (). add_class (Granite.STYLE_CLASS_H2_LABEL);
        new_files_header.add (new_label);

        var new_files_grid = new Gtk.Grid ();
        new_files_grid.valign = Gtk.Align.END;
        new_files_grid.orientation = Gtk.Orientation.VERTICAL;
        new_files_grid.add (new_files_header);
        new_files_grid.add (new_scrolled_window);

        var lists_grid = new Gtk.Grid ();
        lists_grid.orientation = Gtk.Orientation.HORIZONTAL;
        lists_grid.column_spacing = 32;
        lists_grid.column_homogeneous = true;
        lists_grid.margin = 12;
        lists_grid.add (old_files_grid);
        lists_grid.add (new_files_grid);

        add (controls_grid);
        add (modifier_grid);
        add (lists_grid);

        reset ();

        sort_by_combo.changed.connect (() => {
            old_list.set_default_sort_func (old_list_sorter);

            update_view ();
        });

        sort_type_switch.notify ["active"].connect (() => {
            old_list.set_default_sort_func (old_list_sorter);
            update_view ();
        });

        base_name_combo.changed.connect (() => {
            base_name_entry_revealer.reveal_child = base_name_combo.get_active () == RenameBase.CUSTOM;
            update_view ();
        });

        base_name_entry.focus_out_event.connect (() => {
            update_view ();
            return Gdk.EVENT_PROPAGATE;
        });

        base_name_entry.activate.connect (() => {
            update_view ();
        });

        add_button.clicked.connect (() => {
            add_modifier (true);
        });

        add_modifier (false);
    }

    public void add_files (File[] files) {
        if (files.length < 1 || files[0] == null) {
            return;
        }

        if (directory == "") {
            directory = Path.get_dirname (files[0].get_path ());
        }

        string query_info_string = string.join (",", FileAttribute.STANDARD_TARGET_URI,
                                                     FileAttribute.TIME_CREATED,
                                                     FileAttribute.TIME_MODIFIED);
        Gtk.TreeIter? iter = null;
        foreach (File f in files) {
            var path = f.get_path ();
            var dir = Path.get_dirname (path);
            if (dir == directory) {
                var basename = Path.get_basename (path);
                file_map.@set (basename, f);
                old_list.append (out iter);
                old_list.set (iter, 0, basename);
                number_of_files++;

                f.query_info_async.begin (query_info_string,
                                          FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                          Priority.DEFAULT,
                                          null, /* No cancellable for now */
                                          (object, res) => {

                    try {
                        var info = f.query_info_async.end (res);
                        info_map_mutex.@lock ();
                        file_info_map.@set (basename, info.dup ());
                        info_map_mutex.@unlock ();
                    } catch (Error e) {

                    }
                });

            }
        }

        old_list.set_default_sort_func (old_list_sorter);
        update_view ();
    }

    public void add_modifier (bool allow_remove) {
        var mod = new Modifier (allow_remove);
        modifier_chain.add (mod);
        modifier_listbox.add (mod);
        mod.update_request.connect (update_view);
        mod.remove_request.connect (() => {
            modifier_chain.remove (mod);
            mod.destroy ();
            queue_draw ();
            update_view ();
        });

        update_view ();
    }

    public void reset () {
        base_name_combo.set_active (RenameBase.ORIGINAL);
        base_name_entry.text = "";

        bool first = true;
        foreach (var mod in modifier_chain) {
            if (first) {
                mod.reset ();
                first = false;
            } else {
                mod.destroy ();
            }
        }

        update_view ();
    }

    public void rename_files () {
        var new_files = new File[number_of_files];
        int index = 0;
        var undo_map = new Gee.HashMap<string, string> ();

        old_list.@foreach ((m, p, i) => {
            string input_name = "";
            string output_name = "";
            File? result = null;
            Gtk.TreeIter? iter = null;
            old_list.get_iter (out iter, p);
            old_list.@get (iter, 0, out input_name);
            new_list.get_iter (out iter, p);
            new_list.@get (iter, 0, out output_name);
            var file = file_map.@get (input_name);

            if (file != null) {
                try {
                    result = file.set_display_name (output_name);
                    new_files[index++] = result;
                    undo_map.@set (output_name, input_name);
                } catch (GLib.Error e) {
                    new_files[index++] = file;
                    undo_map.@set (input_name, input_name);
                }
            }

            return false; /* Continue iteration (compare HashMap iterator which is opposite!) */
        });

        undo_stack.offer_head (undo_map);
        can_undo = true;

        replace_files (new_files);

        reset ();
    }

    private uint view_update_timeout_id = 0;
    public void schedule_view_update () {
        var delay = int.min (number_of_files * modifier_chain.size, 500);
        if (delay < 20) {
            update_view ();
        } else {
            if (view_update_timeout_id > 0) {
                Source.remove (view_update_timeout_id);
            }

            view_update_timeout_id = Timeout.add (delay, () => {
                update_view ();
                view_update_timeout_id = 0;
                return Source.REMOVE;
            });
        }

    }

    private void update_view () {
        can_rename = true;
        int index = 0;
        string output_name = "";
        string input_name = "";
        string file_name = "";
        string extension = "";
        string previous_final_name = "";

        new_list.clear ();

        bool custom_basename = base_name_combo.get_active () == RenameBase.CUSTOM;
        Gtk.TreeIter? new_iter = null;
        old_list.@foreach ((m, p, iter) => {
            old_list.@get (iter, 0, out file_name);

            if (custom_basename) {
                input_name = base_name_entry.get_text ();
            } else {
                input_name = strip_extension (file_name, out extension);
            }

            foreach (Modifier mod in modifier_chain) {
                output_name = mod.rename (input_name, index);
                input_name = output_name;
            }

            var final_name = output_name.concat (extension);
            bool name_valid = true;

            if (final_name == previous_final_name ||
                final_name == file_name) {

                debug ("blank or duplicate name");
                name_valid = false;
                can_rename = false;
                /* TODO Visual indication of problem output name */
            }

            new_list.append (out new_iter);
            new_list.@set (new_iter, 0, final_name, 1, name_valid, -1);

            previous_final_name = final_name;
            index++;
            return false;
        });
    }

    private string strip_extension (string filename, out string extension) {
        var extension_pos = filename.last_index_of_char ('.', 0);
        if (filename.length < 4 || extension_pos < filename.length - 4) {
            extension = "";
            return filename;
        } else {
            extension = filename [extension_pos : filename.length];
            return filename [0 : extension_pos];
        }
    }

    public int old_list_sorter (Gtk.TreeModel m, Gtk.TreeIter a, Gtk.TreeIter b) {
        int res = 0;
        string name_a = "";
        string name_b = "";
        m.@get (a, 0, out name_a);
        m.@get (b, 0, out name_b);

        switch (sort_by_combo.get_active ()) {
            case RenameSortBy.NAME:
                res = name_a.collate (name_b);
                break;

            case RenameSortBy.CREATED:
                var time_a = file_info_map.@get (name_a).get_attribute_uint64 (FileAttribute.TIME_CREATED);
                var time_b = file_info_map.@get (name_b).get_attribute_uint64 (FileAttribute.TIME_CREATED);

                if (time_a == time_b) {
                    res = name_a.collate (name_b);
                } else {
                    res = time_a > time_b ? 1 : -1;
                }

                break;

            case RenameSortBy.MODIFIED:
                var time_a = file_info_map.@get (name_a).get_attribute_uint64 (FileAttribute.TIME_MODIFIED);
                var time_b = file_info_map.@get (name_b).get_attribute_uint64 (FileAttribute.TIME_MODIFIED);

                if (time_a == time_b) {
                    res = name_a.collate (name_b);
                } else {
                    res = time_a > time_b ? 1 : -1;
                }

                break;

            default:
                assert_not_reached ();
        }

        if (sort_type_switch.active) {
            res = -res;
        }

        return res;
    }

    private void replace_files (File[] files) {
        old_list.clear ();
        new_list.clear ();
        number_of_files = 0;
        file_map.clear ();
        file_info_map.clear ();

        add_files (files);
    }

    public void undo () {
        Gee.HashMap<string, string>? restore_map = undo_stack.poll_head ();
        can_undo = undo_stack.size > 0;

        if (restore_map == null) {
            return;
        }

        var new_files = new File[restore_map.size];
        var restore_iterator = restore_map.map_iterator ();
        int index = 0;

        restore_iterator.@foreach ((new_name, original_name) => {
            File? result = null;
            var path = Path.build_path (Path.DIR_SEPARATOR_S, directory, new_name);
            var file = File.new_for_path (path);

            if (file != null) {
                try {
                    result = file.set_display_name (original_name);
                    new_files[index++] = result;
                } catch (GLib.Error e) {
                    new_files[index++] = file;
                }
            }

            return true; /* Continue iteration */
        });

        replace_files (new_files);
    }
}


