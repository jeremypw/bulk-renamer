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

public class Renamer : Gtk.Box {
    private Gtk.TreeView old_file_names;
    private Gtk.TreeView new_file_names;
    private Gtk.Entry name_entry;
    private Gtk.Entry number_entry;
    private Gtk.ComboBoxText naming_combo;
    private Gtk.ListStore old_list;
    private Gtk.ListStore new_list;
    private Gtk.TreeIter iter;
    private string directory;
    private Gee.HashMap<string, File> file_map;
    private int naming_offset;
    private Gtk.Switch name_switch;

    public Gtk.Button preview_button { get; construct; }

    public Renamer (File[]? files = null) {
        Object (orientation: Gtk.Orientation.VERTICAL,
                spacing: 12,
                border_width: 18
       );

        if (files != null) {
            add_files (files);
        }
    }

    construct {
        file_map = new Gee.HashMap<string, File> ();
        directory = "";

        var controls = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        var lists = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        var buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        naming_offset = 0;

        name_entry = new Gtk.Entry ();
        name_entry.placeholder_text = _("Enter naming scheme");

        name_switch = new Gtk.Switch ();
        name_switch.active = true;

        number_entry = new Gtk.Entry ();
        number_entry.placeholder_text = _("Start from");

        var naming_label = new Gtk.Label (_("Naming:"));

        naming_combo = new Gtk.ComboBoxText ();
        naming_combo.append_text (_("1,2,3…"));
        naming_combo.append_text (_("01,02,03…"));
        naming_combo.append_text (_("001,002,003…"));
        naming_combo.append_text (_("Current Date"));
        naming_combo.append_text (_("Search and Replace"));
        naming_combo.active = 0;

        var cell = new Gtk.CellRendererText ();
        old_list = new Gtk.ListStore (1, typeof (string));
        old_file_names = new Gtk.TreeView.with_model (old_list);
        old_file_names.insert_column_with_attributes (-1, _("Old Name"), cell, "text", 0);
        old_file_names.get_column (0).max_width = 50;

        new_list = new Gtk.ListStore (1, typeof (string));
        new_file_names = new Gtk.TreeView.with_model (new_list);
        new_file_names.insert_column_with_attributes (-1, _("New Name"), cell, "text", 0);
        new_file_names.get_column (0).max_width = 50;

        naming_combo.changed.connect (() => {
            if (naming_combo.get_active () == 3) {
                number_entry.hide ();
                naming_label.hide ();
                name_entry.hide ();
                name_switch.hide ();
            } else if (naming_combo.get_active () == 4) {
                name_switch.set_active (true);
                name_entry.placeholder_text = _("Search for");
                number_entry.placeholder_text = _("Replace with");
                name_entry.text = "";
                number_entry.text = "";
                name_entry.show ();
                number_entry.show ();
                naming_label.show ();
                name_switch.hide ();
            } else {
                if (name_entry.placeholder_text != _("Enter naming scheme")) {
                    name_entry.placeholder_text = _("Enter naming scheme");
                    number_entry.placeholder_text = _("Start from");
                    name_entry.text = "";
                    number_entry.text = "";
                }

                number_entry.show ();
                naming_label.show ();
                name_entry.show ();
                name_switch.show ();
            }
        });

        name_switch.notify["active"].connect (() => {
            if (name_switch.active) {
                name_entry.set_sensitive (true);
                name_entry.placeholder_text = _("Enter naming scheme");
            } else {
                name_entry.set_sensitive (false);
                name_entry.placeholder_text = "";
                name_entry.text = "";
            }
        });

        var old_scrolled_window = new Gtk.ScrolledWindow (null, null);
        old_scrolled_window.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        old_scrolled_window.add (old_file_names);
        old_scrolled_window.set_min_content_height (300);

        var new_scrolled_window = new Gtk.ScrolledWindow (null, null);
        new_scrolled_window.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        new_scrolled_window.add (new_file_names);
        new_scrolled_window.set_min_content_height (300);

        preview_button = new Gtk.Button.with_label (_("Update Preview"));
        preview_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        controls.pack_start (naming_label, false, false, 0);
        controls.pack_start (name_switch, false, false, 0);
        controls.pack_start (name_entry, true, false, 0);
        buttons.pack_end (preview_button, false , false, 0);
        controls.pack_end (naming_combo, false, false, 0);
        controls.pack_end (number_entry, true, false, 0);

        lists.pack_start (old_scrolled_window, true, true, 0);
        lists.pack_end (new_scrolled_window, true, true, 0);

        pack_start (controls, false, false, 0);
        pack_start (lists, true, true, 0);
        pack_start (buttons, true, false, 0);
    }

    public void add_files (File[] files) {
        if (files.length < 1 || files[0] == null) {
            return;
        }

        if (directory == "") {
            directory = Path.get_dirname (files[0].get_path ());
        }

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
    }

    public void rename_files () throws GLib.Error {
        old_list.@foreach ((m, p, i) => {
            string input_name, output_name;
            old_list.@get (i, 0, out input_name);
            new_list.@get (i, 0, out output_name);
            var file = file_map.@get (input_name);
            if (file != null) {
                try {
                    file.set_display_name (output_name);
                } catch (GLib.Error e) {
                    return true;
                }
            }

            return false;
        });
    }

    public void update_view () {
        if (number_entry.get_text () != "") {
            naming_offset = int.parse (number_entry.get_text ()) - 1;
        } else {
            naming_offset = 0;
        }

        preview_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        new_list.clear ();

        var name_root = name_switch.active ? name_entry.get_text () : "";
        bool use_name_root = name_root.length > 0;
        int index = naming_offset;

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
                case 3: // "001,002,003…"
                    var dt = new GLib.DateTime.now_local ();
                    index_string = dt.format ("-%Y-%m-%d");
                    break;
                case 4: //Search and Replace
                    break;

                default:
                    break;
            }

            string output_name;
            m.@get (i, 0, out output_name);

            if (index_string != "") {
                if (use_name_root) {
                    output_name = name_root;
                }

                StringBuilder sb = new StringBuilder (output_name);
                var extension_pos = output_name.last_index_of_char ('.', 0);
                if (extension_pos < output_name.length - 4) {
                    extension_pos = output_name.length - 1;
                }

                sb.insert (extension_pos + 1, index_string);
                output_name = sb.str;
            } else {
                m.@get (i, 0, out output_name);
                output_name = output_name.replace (name_entry.get_text (), number_entry.get_text ());
            }

            new_list.append (out iter);
            new_list.set (iter, 0, output_name);
            index++;
            return false;
        });
    }
}
