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

public class BulkRenamer : Gtk.Box {
    private Gtk.TreeView old_file_names;
    private Gtk.TreeView new_file_names;
    private Gtk.Entry name_entry;
    private Gtk.Entry number_entry;
    private Gtk.ComboBoxText naming_combo;
    public Gtk.Button preview_button;
    private Gtk.ListStore old_list;
    private Gtk.ListStore new_list;
    private Gtk.TreeIter iter;
    private string directory;
    private Array<string> input_files = new Array<string> ();
    private int naming_offset;
    private Array<string> output_files = new Array<string> ();
    private Gtk.Switch name_switch;
    public BulkRenamer (string[] files) {
        Object( orientation: Gtk.Orientation.VERTICAL, spacing: 0 );
        var controls = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        var lists = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        var buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        naming_offset = 0;
        name_entry = new Gtk.Entry ();
        name_entry.placeholder_text = "Enter naming scheme";
        name_switch = new Gtk.Switch ();
        name_switch.set_active(true);
        number_entry = new Gtk.Entry ();
        number_entry.placeholder_text = "Start from";
        var naming_label = new Gtk.Label ("Naming:");
        naming_combo = new Gtk.ComboBoxText ();
        naming_combo.append_text ("1,2,3,\u2026");
        naming_combo.append_text ("01,02,03,\u2026");
        naming_combo.append_text ("001,002,003,\u2026");
        naming_combo.append_text ("Current Date");
        naming_combo.append_text ("Search and Replace");
        naming_combo.active = 0;
        old_list = new Gtk.ListStore ( 1, typeof(string));
        new_list = new Gtk.ListStore ( 1, typeof(string));
        old_file_names = new Gtk.TreeView.with_model (old_list);
        new_file_names = new Gtk.TreeView.with_model (new_list);
        this.border_width = 18;
        this.spacing = 12;
        Gtk.CellRendererText cell = new Gtk.CellRendererText ();
        old_file_names.insert_column_with_attributes (-1, "Old Name", cell, "text", 0);
        new_file_names.insert_column_with_attributes (-1, "New Name", cell, "text", 0);
        old_file_names.get_column (0).max_width = 50;
        new_file_names.get_column (0).max_width = 50;
        int i = 0;
        int directory_index = 0;
        foreach (string fn in files) {
            if(i==0) {
                i++;
                continue;
            }
            if(i==1) {
                directory_index = fn.last_index_of_char('/',0);
            }
            directory = fn.slice (0, directory_index+1);
            string basename = fn.slice (directory_index+1, fn.length);
            input_files.append_val (basename);
            old_list.append (out iter);
            old_list.set ( iter, 0, basename);
            i++;
        }
        naming_combo.changed.connect (() => {
            if(naming_combo.get_active() == 3) {
                number_entry.hide();
                naming_label.hide();
                name_entry.hide();
                name_switch.hide();
            }
            else if(naming_combo.get_active() == 4) {
                name_switch.set_active(true);
                name_entry.placeholder_text = "Search for";
                number_entry.placeholder_text = "Replace with";
                name_entry.text = "";
                number_entry.text = "";
                name_entry.show();
                number_entry.show();
                naming_label.show();
                name_switch.hide();
            }
            else {
                if(name_entry.placeholder_text != "Enter naming scheme"){
                    name_entry.placeholder_text = "Enter naming scheme";
                    number_entry.placeholder_text = "Start from";
                    name_entry.text = "";
                    number_entry.text = "";
                }
                number_entry.show();
                naming_label.show();
                name_entry.show();
                name_switch.show();
            }
        });
        name_switch.notify["active"].connect (() => {
            if (name_switch.active) {
                name_entry.set_sensitive(true);
                name_entry.placeholder_text = "Enter naming scheme";
            } else {
                name_entry.set_sensitive(false);
                name_entry.placeholder_text = "";
                name_entry.text = "";
            }
        });
        var old_scrolled_window = new Gtk.ScrolledWindow(null, null);
        old_scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        old_scrolled_window.add(old_file_names);
        old_scrolled_window.set_min_content_height(300);
        var new_scrolled_window = new Gtk.ScrolledWindow(null, null);
        new_scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        new_scrolled_window.add(new_file_names);
        new_scrolled_window.set_min_content_height(300);
        preview_button = new Gtk.Button.with_label ("Update Preview");
        preview_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        controls.pack_start (naming_label,false,false,0);
        controls.pack_start (name_switch,false,false,0);
        controls.pack_start (name_entry,true, false, 0);
        buttons.pack_end (preview_button, false,false,0);
        controls.pack_end (naming_combo, false,false,0);
        controls.pack_end (number_entry, true, false, 0);
        lists.pack_start (old_scrolled_window, true, true, 0);
        lists.pack_end (new_scrolled_window, true, true, 0);
        this.pack_start (controls, false, false, 0);
        this.pack_start (lists, true, true, 0);
        this.pack_start (buttons,true,false,0);
    }
    public void rename_files (){
        for (int i = 0; i < input_files.length; i++) {
            var file = File.new_for_path(directory.concat (input_files.index(i)));
            try {
                file.set_display_name (output_files.index(i));
            } catch (Error e){
                stdout.printf ("File %s not found\n",input_files.index(i));
            }
        }
    }
    public void update_view (){
        int index_of_char;
        string extension, file_name, base_no_extension;
        output_files.remove_range(0, output_files.length);
        if(number_entry.get_text ()!=""){
                naming_offset = int.parse (number_entry.get_text ()) - 1;
        }
        preview_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        new_list.clear ();
            switch (naming_combo.get_active()) {
            case  0:
                for (int i = 0; i < input_files.length; i++) {
                    index_of_char = input_files.index (i).last_index_of_char ('.',0);
                    extension = input_files.index (i).slice (index_of_char, input_files.index (i).length);
                    new_list.append (out iter);
                    if(name_entry.get_text() == "" && name_switch.get_active() == false){
                        base_no_extension = input_files.index(i).slice(0, index_of_char);
                        file_name = base_no_extension.concat ( (i + 1 + naming_offset).to_string (),extension);
                    }
                    else{
                        file_name = name_entry.get_text().concat ( (i + 1 + naming_offset).to_string (),extension);
                    }
                    new_list.set ( iter, 0, file_name);
                    output_files.append_val (file_name);
                }
                break;
            case  1:
                for (int i = 0; i < input_files.length; i++) {
                    index_of_char = input_files.index (i).last_index_of_char ('.',0);
                    extension = input_files.index (i).slice (index_of_char, input_files.index (i).length);
                    new_list.append (out iter);
                    if(name_entry.get_text() == "" && name_switch.get_active() == false){
                        base_no_extension = input_files.index(i).slice(0, index_of_char);
                        if(i + naming_offset < 9) {
                            file_name = base_no_extension.concat("0",(i + 1 + naming_offset).to_string(),extension);
                        }
                        else {
                            file_name = base_no_extension.concat((i + 1 + naming_offset).to_string(),extension);
                        }
                    }
                    else {
                        if(i + naming_offset < 9) {
                            file_name = name_entry.get_text().concat("0",(i + 1 + naming_offset).to_string(),extension);
                        }
                        else {
                            file_name = name_entry.get_text().concat((i + 1 + naming_offset).to_string(),extension);
                        }
                    }
                    new_list.set ( iter, 0, file_name);
                    output_files.append_val (file_name);
                }
                break;
            case  2:
                for (int i = 0; i < input_files.length; i++) {
                    index_of_char = input_files.index(i).last_index_of_char('.',0);
                    extension = input_files.index(i).slice(index_of_char, input_files.index(i).length);
                    new_list.append(out iter);
                    if(name_entry.get_text() == "" && name_switch.get_active() == false){
                        base_no_extension = input_files.index(i).slice(0, index_of_char);
                        if(i + naming_offset < 9) {
                            file_name = base_no_extension.concat("00",(i + 1 + naming_offset).to_string(),extension);
                        }
                        else if(i + naming_offset < 99) {
                            file_name = base_no_extension.concat("0",(i + 1 + naming_offset).to_string(),extension);
                        }
                        else {
                            file_name = base_no_extension.concat((i + 1 + naming_offset).to_string(),extension);
                        }
                    }
                    else {
                        if(i + naming_offset < 9) {
                            file_name = name_entry.get_text().concat("00",(i + 1 + naming_offset).to_string(),extension);
                        }
                        else if(i + naming_offset < 99) {
                            file_name = name_entry.get_text().concat("0",(i + 1 + naming_offset).to_string(),extension);
                        }
                        else {
                            file_name = name_entry.get_text().concat((i + 1 + naming_offset).to_string(),extension);
                        }
                    }
                    
                    new_list.set ( iter, 0, file_name);
                    output_files.append_val (file_name);
                }
                break;
            case  3:
                var dt = new GLib.DateTime.now_local ();
                for (int i = 0; i < input_files.length; i++) {
                    index_of_char = input_files.index(i).last_index_of_char('.',0);
                    extension = input_files.index(i).slice(index_of_char, input_files.index(i).length);
                    base_no_extension = input_files.index(i).slice(0, index_of_char);
                    new_list.append(out iter);
                    file_name = base_no_extension.concat(dt.format ("-%Y-%m-%d"),extension);
                    new_list.set ( iter, 0, file_name);
                    output_files.append_val (file_name);
                    }
                break;
            case 4:
                if(name_entry.get_text() == ""){
                    for (int i = 0; i < input_files.length; i++) {
                        new_list.append(out iter);
                        file_name = input_files.index(i);
                        new_list.set ( iter, 0, file_name);
                        output_files.append_val (file_name);
                    }
                }
                else{
                    for (int i = 0; i < input_files.length; i++) {
                        index_of_char = input_files.index(i).last_index_of_char('.',0);
                        extension = input_files.index(i).slice(index_of_char, input_files.index(i).length);
                        base_no_extension = input_files.index(i).slice(0, index_of_char);
                        base_no_extension = base_no_extension.replace(name_entry.get_text(), number_entry.get_text());
                        new_list.append(out iter);
                        file_name = base_no_extension.concat(extension);
                        new_list.set ( iter, 0, file_name);
                        output_files.append_val (file_name);
                    }
                }
                break;
            }
    }
}
