/*
 * Copyright (C) 2010-2017  Vartan Belavejian
 * Copyright (C) 2019-2020     Jeremy Wootten
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
    public Gee.ArrayList<Modifier> modifier_chain { get; private set; }
    private Gee.LinkedList<Gee.HashMap<string, string>> undo_stack;

    private Gtk.Grid modifier_grid;
    private Gtk.ListBox modifier_listbox;

    private Gtk.TreeView old_file_names;
    private Gtk.TreeView new_file_names;
    private Gtk.ListStore old_list;
    private Gtk.ListStore new_list;
    private Icon invalid_icon;

    private Gtk.Entry base_name_entry;
    private Gtk.ComboBoxText base_name_combo;
    private Gtk.Switch protect_extension_switch;
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
        info_map_mutex = Mutex ();
        invalid_icon = new ThemedIcon.with_default_fallbacks ("dialog-warning");
        can_rename = false;
        orientation = Gtk.Orientation.VERTICAL;
        directory = "";

        file_map = new Gee.HashMap<string, File> ();
        file_info_map = new Gee.HashMap<string, FileInfo> ();
        modifier_chain = new Gee.ArrayList<Modifier> ();
        undo_stack = new Gee.LinkedList<Gee.HashMap<string, string>> ();

        var base_name_label = new Granite.HeaderLabel (_("Base"));
        base_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        base_name_combo = new Gtk.ComboBoxText () {
            valign = Gtk.Align.CENTER
        };

        base_name_combo.insert (RenameBase.CUSTOM, "CUSTOM", RenameBase.CUSTOM.to_string ());
        base_name_combo.insert (RenameBase.ORIGINAL, "ORIGINAL", RenameBase.ORIGINAL.to_string ());

        base_name_entry = new Gtk.Entry () {
            placeholder_text = _("Enter naming scheme"),
            hexpand = false,
            max_width_chars = 64,
            valign = Gtk.Align.CENTER
        };

        var protect_extension_label = new Gtk.Label (_("Protect Extension")) {
            vexpand = true,
            valign = Gtk.Align.CENTER
        };

        protect_extension_switch = new Gtk.Switch () {
            vexpand = false,
            valign = Gtk.Align.CENTER,
            active = true
        };

        var protect_extension_grid = new Gtk.Grid () {
            column_spacing = 6,
            tooltip_text = _("Do not apply changes to file extension")
        };

        protect_extension_grid.attach (protect_extension_label, 0, 0, 1, 1);
        protect_extension_grid.attach (protect_extension_switch, 1, 0, 1, 1);

        var controls_stack = new Gtk.Stack ();
        controls_stack.add (base_name_entry);
        controls_stack.add (protect_extension_grid);

        var controls_grid = new Gtk.Grid () {
            vexpand = false,
            orientation = Gtk.Orientation.HORIZONTAL,
            column_spacing = 12,
            margin_bottom = 12
        };

        controls_grid.attach (base_name_label, 0, 0, 2, 1);
        controls_grid.attach (base_name_combo, 0, 1, 1, 1);
        controls_grid.attach (controls_stack, 2, 1, 1, 1);

        var modifiers_label = new Granite.HeaderLabel (_("Modifiers"));
        modifiers_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        modifier_listbox = new Gtk.ListBox ();

        var add_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            image = new Gtk.Image.from_icon_name ("add", Gtk.IconSize.DND),
            tooltip_text = _("Add another modifier"),
            sensitive = true
        };
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var clear_mods_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            image = new Gtk.Image.from_icon_name ("edit-clear", Gtk.IconSize.DND),
            tooltip_text = _("Clear modifiers"),
            sensitive = true
        };
        clear_mods_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var action_bar = new Gtk.ActionBar () {
            margin_top = 12
        };
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.pack_start (add_button);
        action_bar.pack_end (clear_mods_button);

        modifier_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            margin_bottom = 12,
            row_spacing = 0
        };
        modifier_grid.add (modifiers_label);
        modifier_grid.add (modifier_listbox);
        modifier_grid.add (action_bar);

        var cell = new Gtk.CellRendererText () {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            wrap_mode = Pango.WrapMode.CHAR,
            width_chars = 64
        };

        old_list = new Gtk.ListStore (1, typeof (string));
        old_list.set_default_sort_func (old_list_sorter);
        old_list.set_sort_column_id (Gtk.SortColumn.DEFAULT, Gtk.SortType.ASCENDING);

        old_file_names = new Gtk.TreeView.with_model (old_list) {
            hexpand = true,
            headers_visible = false
        };
        old_file_names.insert_column_with_attributes (-1, "ORIGINAL", cell, "text", 0);

        var original_label = new Granite.HeaderLabel (_("Original Names")) {
            valign = Gtk.Align.CENTER
        };
        original_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var clear_button = new Gtk.Button.from_icon_name ("edit-clear-all", Gtk.IconSize.LARGE_TOOLBAR);
        clear_button.action_name = "win.action-clear-files";
        clear_button.tooltip_markup = Granite.markup_accel_tooltip (
            ((Gtk.Application)Application.get_default ()).get_accels_for_action (clear_button.action_name),
            _("Clear the original file list")
        );
        clear_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var sort_by_label = new Gtk.Label (_("Sort by:"));

        sort_by_combo = new Gtk.ComboBoxText () {
            valign = Gtk.Align.CENTER,
            margin = 3
        };
        sort_by_combo.insert (RenameSortBy.NAME, "NAME", RenameSortBy.NAME.to_string ());
        sort_by_combo.insert (RenameSortBy.CREATED, "CREATED", RenameSortBy.CREATED.to_string ());
        sort_by_combo.insert (RenameSortBy.MODIFIED, "MODIFIED", RenameSortBy.MODIFIED.to_string ());
        sort_by_combo.set_active (RenameSortBy.NAME);

        var sort_by_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL,
            column_spacing = 6,
            halign = Gtk.Align.END,
            valign = Gtk.Align.CENTER
        };
        sort_by_grid.add (sort_by_label);
        sort_by_grid.add (sort_by_combo);

        var sort_type_label = new Gtk.Label (_("Reverse"));

        sort_type_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER
        };

        var sort_type_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL,
            column_spacing = 6,
            halign = Gtk.Align.END,
            valign = Gtk.Align.CENTER,
            margin = 3
        };
        sort_type_grid.add (sort_type_switch);
        sort_type_grid.add (sort_type_label);

        var old_files_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        old_files_header.add (original_label);

        old_files_header.pack_end (clear_button, false, false, 6);
        old_files_header.pack_end (sort_type_grid, false, false, 6);
        old_files_header.pack_end (sort_by_grid, false, false, 6);

        var header_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.VERTICAL);
        header_size_group.add_widget (old_files_header);

        var old_scrolled_window = new OldFilesList ();
        old_scrolled_window.files_dropped.connect ((file_array) => {
            add_files (file_array);
        });

        old_scrolled_window.add (old_file_names);

        var vadj = old_scrolled_window.get_vadjustment ();

        var old_files_grid = new Gtk.Grid () {
            valign = Gtk.Align.START,
            orientation = Gtk.Orientation.VERTICAL
        };
        old_files_grid.add (old_files_header);
        old_files_grid.add (old_scrolled_window);

        var invalid_renderer = new Gtk.CellRendererPixbuf () {
            gicon = invalid_icon,
            visible =false,
            xalign = 1.0f
        };

        var new_cell = new Gtk.CellRendererText () {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            wrap_mode = Pango.WrapMode.CHAR,
            width_chars = 64
        };

        new_list = new Gtk.ListStore (2, typeof (string), typeof (bool));
        new_file_names = new Gtk.TreeView.with_model (new_list);
        var text_col = new Gtk.TreeViewColumn.with_attributes (
            "NEW", new_cell,
            "text", 0
        );

        text_col.set_cell_data_func (new_cell, (col, cell, model, iter) => {
            bool invalid;
            model.@get (iter, 1, out invalid);
            new_cell.sensitive = !invalid;
        });

        new_file_names.insert_column (text_col, 0);

        new_file_names.insert_column_with_attributes (
            -1, "VALID", invalid_renderer,
            "visible", 1
        );
        new_file_names.headers_visible = false;

        var new_scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hexpand = true,
            vadjustment = vadj,
            min_content_height = 300,
            max_content_height = 2000,
            overlay_scrolling = true
        };

        new_scrolled_window.add (new_file_names);
        new_scrolled_window.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.EXTERNAL);

        var new_files_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        header_size_group.add_widget (new_files_header);

        var new_label = new Granite.HeaderLabel (_("New Names")) {
            valign = Gtk.Align.CENTER
        };
        new_label.get_style_context (). add_class (Granite.STYLE_CLASS_H2_LABEL);
        new_files_header.add (new_label);

        var new_files_grid = new Gtk.Grid () {
            valign = Gtk.Align.END,
            orientation = Gtk.Orientation.VERTICAL
        };
        new_files_grid.add (new_files_header);
        new_files_grid.add (new_scrolled_window);

        var lists_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL,
            column_spacing = 32,
            column_homogeneous = true,
            margin = 12
        };
        lists_grid.add (old_files_grid);
        lists_grid.add (new_files_grid);

        add (controls_grid);
        add (modifier_grid);
        add (lists_grid);

        add_modifier (false);

        show_all ();

        sort_by_combo.changed.connect (() => {
            old_list.set_default_sort_func (old_list_sorter);

            schedule_view_update ();
        });

        sort_type_switch.notify ["active"].connect (() => {
            old_list.set_default_sort_func (old_list_sorter);
            schedule_view_update ();
        });

        base_name_combo.changed.connect (() => {
            switch (base_name_combo.get_active ()) {
                case RenameBase.ORIGINAL:
                    controls_stack.visible_child = protect_extension_grid;
                    break;
                case RenameBase.CUSTOM:
                    controls_stack.visible_child = base_name_entry;
                    break;
                default:
                    break;
            }

            schedule_view_update ();
        });

        base_name_combo.active = RenameBase.ORIGINAL;
        controls_stack.visible_child = protect_extension_grid;

        base_name_entry.changed.connect (() => {
            schedule_view_update ();
        });

        add_button.clicked.connect (() => {
            add_modifier (true);
        });

        clear_mods_button.clicked.connect (clear_mods);
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
        foreach (unowned File f in files) {
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
                        warning ("Error querying info %s", e.message);
                    }
                });

            }
        }

        old_list.set_default_sort_func (old_list_sorter);
        schedule_view_update ();
    }

    public Modifier add_modifier (bool allow_remove) {
        var mod = new Modifier (allow_remove);
        modifier_chain.add (mod);
        modifier_listbox.add (mod);
        mod.update_request.connect (schedule_view_update);
        mod.remove_request.connect (() => {
            modifier_chain.remove (mod);
            mod.destroy ();
            queue_draw ();
            schedule_view_update ();
        });

        schedule_view_update ();

        return mod;
    }

    public void clear_mods () {
        foreach (var mod in modifier_listbox.get_children ()) {
            mod.destroy ();
        }

        modifier_chain.clear ();
        add_modifier (false);
    }

    public void set_sort_order (RenameSortBy sort_by, bool reversed) {
        sort_by_combo.set_active (sort_by);
        sort_type_switch.active = reversed;
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

        clear_files ();
    }

    private uint view_update_timeout_id = 0;
    private void schedule_view_update () {
        if (view_update_timeout_id > 0) {
            Source.remove (view_update_timeout_id);
        }

        view_update_timeout_id = Timeout.add (250, () => {
            if (updating) {
                return Source.CONTINUE;
            }

            view_update_timeout_id = 0;
            update_view ();

            return Source.REMOVE;
        });
    }

    private bool updating = false;
    private void update_view () {
        updating = true;
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
            } else if (protect_extension_switch.active) {
                input_name = strip_extension (file_name, out extension);
            } else {
                input_name = file_name;
            }

            foreach (Modifier mod in modifier_chain) {
                if (!custom_basename &&
                    !protect_extension_switch.active &&
                    mod.is_suffix ()) {// Do not want to place anything after extension

                    input_name = strip_extension (input_name, out extension);
                    output_name = mod.rename (input_name, index) + extension;
                } else {
                    output_name = mod.rename (input_name, index);
                }

                input_name = output_name;
            }

            string final_name;
            if (protect_extension_switch.active) {
                final_name = output_name.concat (extension);
            } else {
                final_name = output_name;
            }

            bool name_invalid = false;

            if (final_name == previous_final_name ||
                final_name == file_name ||
                invalid_name (final_name, file_name)) {

                warning ("Invalid modified filename %s - blank or duplicate or existing filename", final_name);
                name_invalid = true;
                can_rename = false;
            }

            new_list.append (out new_iter);
            new_list.@set (new_iter, 0, final_name, 1, name_invalid);

            previous_final_name = final_name;
            index++;
            return false;
        });

        updating = false;
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

    private bool invalid_name (string new_name, string input_name) {
        var old_file = file_map.@get (input_name);
        if (old_file == null) {
            return true;
        }

        var new_file = File.new_for_path (
            Path.build_filename (old_file.get_parent ().get_path (), new_name)
        );

        if (new_file.query_exists ()) {
            return true;
        }

        return false;
    }

    private void replace_files (File[] files) {
        clear_files ();
        add_files (files);
    }

    public void clear_files () {
        old_list.clear ();
        new_list.clear ();
        number_of_files = 0;
        file_map.clear ();
        file_info_map.clear ();
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

    public int get_base_type () {
        return base_name_combo.active;
    }

    public void set_base_type (int type) {
        base_name_combo.active = type;
    }

    public string get_custom_base_name () {
        return base_name_combo.active == RenameBase.CUSTOM ? base_name_entry.text : "";
    }

    public void set_custom_base_name (string base_name) {
        base_name_entry.text = base_name;
    }

    public int get_sort_type () {
        return sort_by_combo.active;
    }

    public bool get_reverse_sort () {
        return sort_type_switch.active;
    }

    public bool get_protect_extension () {
        return protect_extension_switch.active;
    }

    public void set_protect_extension (bool protect) {
        protect_extension_switch.active = protect;
    }

/*---------------------------------------------------------------------------------------*/
    private class OldFilesList : Gtk.ScrolledWindow {
        /** Drag and drop support **/
        protected const Gdk.DragAction FILE_DRAG_ACTIONS = Gdk.DragAction.COPY;

        private bool drop_data_ready = false; /* whether the drop data was received already */
        private bool drop_occurred = false; /* whether the data was dropped */
        private File[] drop_file_array = null; /* the list of URIs in the drop data */

        public signal void files_dropped (File[] dropped_files);

        public OldFilesList () {
            /* Drag destination */
            Gtk.TargetEntry target_uri_list = {"text/uri-list", 0, 0};
            Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION,
                               {target_uri_list},
                               FILE_DRAG_ACTIONS);

            drag_data_received.connect (on_drag_data_received);
            drag_drop.connect (on_drag_drop);
        }

        construct {
            hexpand = true;
            min_content_height = 300;
            max_content_height = 2000;
        }

        private void on_drag_data_received (Gdk.DragContext context,
                                            int x, int y,
                                            Gtk.SelectionData selection_data,
                                            uint info, uint time) {
            bool success = false;

            if (!drop_data_ready) {
                string? uris;
                if (selection_data_is_uri_list (selection_data, info, out uris)) {
                    var uri_list = GLib.Uri.list_extract_uris (uris);
                    drop_file_array = new File[uri_list.length];
                    int index = 0;
                    foreach (unowned string uri in uri_list) {
                        drop_file_array[index++] = GLib.File.new_for_uri (uri);
                    }

                    drop_data_ready = true;
                }
            }

            if (drop_data_ready && drop_occurred && info == 0) {
                drop_occurred = false;
                files_dropped (drop_file_array);
                Gtk.drag_finish (context, success, false, time);
            }
        }

        private bool on_drag_drop (Gdk.DragContext context, int x, int y, uint time) {
            drop_occurred = true;
            if (drop_file_array == null) {
                Gtk.TargetList list = null;
                Gdk.Atom target = Gtk.drag_dest_find_target (this, context, list);
                Gtk.drag_get_data (this, context, target, time);
            }

            return false;
        }

        private bool selection_data_is_uri_list (Gtk.SelectionData selection_data, uint info, out string? text) {
            text = null;

            if (info == 0 &&
                selection_data != null &&
                selection_data.get_length () > 0 && //No other way to get length?
                selection_data.get_format () == 8) {

                /* selection_data.get_data () does not work for some reason (returns nothing) */
                var sb = new StringBuilder ("");

                foreach (uchar u in selection_data.get_data_with_length ()) {
                    sb.append_c ((char)u);
                }

                text = sb.str;
            }

            return (text != null);
        }
    }
}
