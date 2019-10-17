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

    private Gtk.Grid modifier_grid;

    private Gtk.TreeView old_file_names;
    private Gtk.TreeView new_file_names;
    private Gtk.ListStore old_list;
    private Gtk.ListStore new_list;

    private Gtk.Entry name_entry;
    private Gtk.Switch name_switch;
    private Gtk.Switch sort_type_switch;

    private Gtk.ComboBoxText sort_by_combo;

    private Mutex info_map_mutex;

    private int number_of_files = 0;

    public bool can_rename { get; set; }
    public string directory { get; private set; default = ""; }

    public Renamer (File[]? files = null) {
        if (files != null) {
            add_files (files);
        }
    }

    construct {
        info_map_mutex = Mutex ();

        can_rename = false;
        orientation = Gtk.Orientation.VERTICAL;
        directory = "";

        file_map = new Gee.HashMap<string, File> ();
        file_info_map = new Gee.HashMap<string, FileInfo> ();
        modifier_chain = new Gee.ArrayList<Modifier> ();

        name_entry = new Gtk.Entry ();
        name_entry.placeholder_text = _("Enter naming scheme");
        name_entry.hexpand = true;

        var name_entry_revealer = new Gtk.Revealer ();
        name_entry_revealer.add (name_entry);

        var name_switch_label = new Gtk.Label (_("Set base name:"));
        name_switch = new Gtk.Switch ();
        name_switch_label.valign = Gtk.Align.CENTER;
        name_switch.active = false;

        var sort_by_label = new Gtk.Label (_("Sort originals by:"));
        sort_by_combo = new Gtk.ComboBoxText ();
        sort_by_combo.valign = Gtk.Align.CENTER;
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
        sort_type_grid.orientation = Gtk.Orientation.HORIZONTAL;
        sort_type_grid.column_spacing = 6;
        sort_type_grid.add (sort_type_switch);
        sort_type_grid.add (sort_type_label);

        var controls_grid = new Gtk.Grid ();
        controls_grid.orientation = Gtk.Orientation.HORIZONTAL;
        controls_grid.column_spacing = 6;
        controls_grid.margin = 6;
        controls_grid.margin_bottom = 12;

        controls_grid.add (name_switch_label);
        controls_grid.add (name_switch);
        controls_grid.add (name_entry_revealer);
        controls_grid.add (sort_by_grid);
        controls_grid.add (sort_type_grid);

        modifier_grid = new Gtk.Grid ();
        modifier_grid.orientation = Gtk.Orientation.VERTICAL;
        modifier_grid.margin = 6;
        modifier_grid.margin_bottom = 12;
        modifier_grid.row_spacing = 3;

        var add_modifier_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        add_modifier_button.halign = Gtk.Align.START;
        add_modifier_button.margin = 6;
        add_modifier_button.set_tooltip_text (_("Add another modification"));

        var cell = new Gtk.CellRendererText ();
        old_list = new Gtk.ListStore (1, typeof (string));
        old_list.set_default_sort_func (old_list_sorter);
        old_list.set_sort_column_id (Gtk.SortColumn.DEFAULT, Gtk.SortType.ASCENDING);


        old_file_names = new Gtk.TreeView.with_model (old_list);
        old_file_names.insert_column_with_attributes (-1, _("Old Name"), cell, "text", 0);

        new_list = new Gtk.ListStore (1, typeof (string));
        new_file_names = new Gtk.TreeView.with_model (new_list);
        new_file_names.insert_column_with_attributes (-1, _("New Name"), cell, "text", 0);

        var old_scrolled_window = new Gtk.ScrolledWindow (null, null);
        old_scrolled_window.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        old_scrolled_window.add (old_file_names);
        old_scrolled_window.set_min_content_height (300);

        var new_scrolled_window = new Gtk.ScrolledWindow (null, null);
        new_scrolled_window.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        new_scrolled_window.add (new_file_names);
        new_scrolled_window.set_min_content_height (300);

        var lists = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 18);
        lists.pack_start (old_scrolled_window);
        lists.pack_end (new_scrolled_window);

        add (controls_grid);
        add (modifier_grid);
        add (add_modifier_button);
        add (lists);

        sort_by_combo.changed.connect (() => {
            old_list.set_default_sort_func (old_list_sorter);
            update_view ();
        });

        sort_type_switch.notify ["active"].connect (() => {
            old_list.set_default_sort_func (old_list_sorter);
            update_view ();
        });

        name_switch.notify["active"].connect (() => {
            if (name_switch.active) {
                name_entry_revealer.reveal_child = true;
                name_entry.placeholder_text = _("Enter naming scheme");
            } else {
                name_entry_revealer.reveal_child = false;
                name_entry.placeholder_text = "";
                name_entry.text = "";
            }
        });

        name_entry.focus_out_event.connect (() => {
            update_view ();
            return Gdk.EVENT_PROPAGATE;
        });

        name_entry.activate.connect (() => {
            update_view ();
        });

        add_modifier_button.clicked.connect (() => {
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
        modifier_grid.add (mod);
        mod.changed.connect (update_view);
        mod.remove_request.connect (() => {
            modifier_chain.remove (mod);
            mod.destroy ();
            update_view ();
        });

        update_view ();
    }

    public void rename_files () {
        var new_files = new File[number_of_files];
        int index = 0;
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
                } catch (GLib.Error e) {
                    return true;
                }
            }

            return false;
        });

        old_list.clear ();
        new_list.clear ();
        number_of_files = 0;
        file_map.clear ();
        file_info_map.clear ();
        add_files (new_files);
        can_rename = false;
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
        new_list.clear ();

        Gtk.TreeIter? iter = null;
        int index = 0;
        string output_name = "";
        string input_name = "";
        string file_name = "";
        string extension = "";
        string last_stripped_name = "";

        old_list.@foreach ((m, p, i) => {
            if (name_switch.active) {
                input_name = name_entry.get_text ();
            } else {
                old_list.@get (i, 0, out file_name);
                input_name = strip_extension (file_name, out extension);
            }

            foreach (Modifier mod in modifier_chain) {
                output_name = mod.rename (input_name, index);
                input_name = output_name;
            }

            new_list.append (out iter);
            new_list.set (iter, 0, output_name.concat (extension));

            var stripped_name = output_name.strip ();
            if (stripped_name == "" || stripped_name == last_stripped_name) {
                critical ("Blank or duplicate output");
                can_rename = false;
                /* TODO Visual indication of problem output name */
            }

            last_stripped_name = stripped_name;
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

                res = time_a > time_b ? 1 : -1; /* Unlikely to be equal */
                break;

            case RenameSortBy.MODIFIED:
                var time_a = file_info_map.@get (name_a).get_attribute_uint64 (FileAttribute.TIME_MODIFIED);
                var time_b = file_info_map.@get (name_b).get_attribute_uint64 (FileAttribute.TIME_MODIFIED);

                res = time_a > time_b ? 1 : -1; /* Unlikely to be equal */
                break;

            default:
                assert_not_reached ();
        }

        if (sort_type_switch.active) {
            res = -res;
        }

        return res;
    }
}


