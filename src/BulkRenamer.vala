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

public enum RenameMode {
    NUMBER,
    DATETIME,
    REPLACE,
    INVALID;

    public string to_string () {
        switch (this) {
            case RenameMode.NUMBER:
                return _("Number sequence");

            case RenameMode.DATETIME:
                return _("Current Date");

            case RenameMode.REPLACE:
                return _("Search and Replace");

            default:
                return "ERROR - unrecognised rename mode";
        }
    }
}

public class Renamer : Gtk.Grid {
    private Gee.HashMap<string, File> file_map;
    private Gee.ArrayList<Modifier> modifier_chain;

    private Gtk.TreeView old_file_names;
    private Gtk.TreeView new_file_names;
    private Gtk.ListStore old_list;
    private Gtk.ListStore new_list;

    private Gtk.Entry name_entry;
    private Gtk.Entry number_entry;
    private Gtk.ComboBoxText naming_combo;
    private int naming_offset;
    private Gtk.Switch name_switch;
    private Gtk.Label name_switch_label;

    public bool can_rename { get; set; }
    public string directory { get; private set; default = ""; }

    public Renamer (File[]? files = null) {
        if (files != null) {
            add_files (files);
        }
    }

    construct {
        can_rename = false;
        orientation = Gtk.Orientation.VERTICAL;
        directory = "";
        naming_offset = 0;

        file_map = new Gee.HashMap<string, File> ();
        modifier_chain = new Gee.ArrayList<Modifier> ();
        modifier_chain.add (new Modifier ());

        name_entry = new Gtk.Entry ();
        name_entry.placeholder_text = _("Enter naming scheme");
        name_entry.hexpand = true;

        name_switch = new Gtk.Switch ();
        name_switch_label = new Gtk.Label (_("Set base name:"));
        name_switch_label.valign = Gtk.Align.CENTER;
        name_switch.active = false;

        var controls_grid = new Gtk.Grid ();
        controls_grid.orientation = Gtk.Orientation.HORIZONTAL;
        controls_grid.column_spacing = 6;
        controls_grid.margin = 6;
        controls_grid.margin_bottom = 12;
        
        controls_grid.add (name_switch_label);
        controls_grid.add (name_switch);
        controls_grid.add (name_entry);

        var modifier_grid = new Gtk.Grid ();
        modifier_grid.orientation = Gtk.Orientation.VERTICAL;
        modifier_grid.margin = 6;
        modifier_grid.margin_bottom = 12;
        modifier_grid.row_spacing = 3;

        foreach (Modifier mod in modifier_chain) {
            modifier_grid.add (mod);
        }

        var cell = new Gtk.CellRendererText ();
        old_list = new Gtk.ListStore (1, typeof (string));
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
        add (lists);
 
        name_switch.notify["active"].connect (() => {
            if (name_switch.active) {
                name_entry.set_sensitive (true);
                name_entry.placeholder_text = _("Enter naming scheme");
            } else {
                name_entry.set_sensitive (false);
                name_entry.placeholder_text = "";
                name_entry.text = "";
            }

            update_view ();
        });

        name_entry.focus_out_event.connect (() => {
            update_view ();
            return Gdk.EVENT_PROPAGATE;
        });

        name_entry.activate.connect (() => {
            update_view ();
        });

    }

    public void add_files (File[] files) {
        if (files.length < 1 || files[0] == null) {
            return;
        }

        if (directory == "") {
            directory = Path.get_dirname (files[0].get_path ());
        }

        Gtk.TreeIter? iter = null;
        foreach (File f in files) {
            var path = f.get_path ();
            var dir = Path.get_dirname (path);
            if (dir == directory) {
                var basename = Path.get_basename (path);
                file_map.@set (basename, f);
                old_list.append (out iter);
                old_list.set (iter, 0, basename);
            }
        }

        update_view ();
    }

    public void rename_files () throws GLib.Error {
        if (!can_rename) {
            return;
        }

        old_list.@foreach ((m, p, i) => {
            string input_name, output_name;
            File? result = null;
            old_list.@get (i, 0, out input_name);
            new_list.@get (i, 0, out output_name);
            var file = file_map.@get (input_name);
            if (file != null) {
                try {
                    result = file.set_display_name (output_name);
                } catch (GLib.Error e) {
                    return true;
                }
            }

            if (result != null) {
                file_map.unset (input_name);
                file_map.@set (output_name, result);
            }

            return false;
        });

        old_list.clear ();
        add_files (file_map.values.to_array ());
        old_file_names.queue_draw ();
        can_rename = false;
    }

    public void update_view () {
        can_rename = true;

        if (number_entry.get_text () != "") {
            naming_offset = int.parse (number_entry.get_text ()) - 1;
        } else {
            naming_offset = 0;
        }

        new_list.clear ();

        var name_root = name_switch.active ? name_entry.get_text () : "";
        bool use_name_root = name_root.length > 0;
        int index = naming_offset;

        Gtk.TreeIter? iter = null;
        old_list.@foreach ((m, p, i) => {
            string index_string = "";

            switch (naming_combo.get_active ()) {
                case 0: // "1,2,3…"
                    index_string = index.to_string ();
                    break;
                case 1: // "01,02,03…"
                    index_string = "%02d".printf (index);
                    break;
                case 2: // "001,002,003…"
                    index_string = "%03d".printf (index);
                    break;
                case 3: // "Current date"
                    var dt = new GLib.DateTime.now_local ();
                    index_string = dt.format ("-%Y-%m-%d");
                    break;
                case 4: //"Search and Replace"
                    break;

                default:
                    break;
            }

            string output_name;
            string input_name;
            old_list.@get (i, 0, out input_name);

            if (index_string != "") {
                if (use_name_root) {
                    input_name = name_root;
                }

                StringBuilder sb = new StringBuilder (input_name);
                var extension_pos = input_name.last_index_of_char ('.', 0);
                if (extension_pos < input_name.length - 4) {
                    extension_pos = input_name.length - 1;
                }

                sb.insert (extension_pos + 1, index_string);
                output_name = sb.str;
            } else { // Search and replace
                old_list.@get (i, 0, out input_name);
                output_name = input_name.replace (name_entry.get_text (), number_entry.get_text ());
            }

            new_list.append (out iter);
            new_list.set (iter, 0, output_name);

            if (output_name.strip () == "" || output_name == input_name) {
                can_rename = false;
                /* TODO Visual indication of problem output name */
            }

            index++;

            return false;
        });
    }
}
