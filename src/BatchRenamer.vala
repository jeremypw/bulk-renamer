public class BatchRenamer : Gtk.Box {
	private Gtk.TreeView old_file_names;
	private Gtk.TreeView new_file_names;
	private Gtk.Entry name_entry;
	private Gtk.ComboBoxText naming_combo;
	public Gtk.Button preview_button;
	private Gtk.ListStore old_list;
	private Gtk.ListStore new_list;
	private Gtk.TreeIter iter;
	private string directory;
	private Array<string> input_files = new Array<string> ();
	private Array<string> output_files = new Array<string> ();
	public BatchRenamer (string[] files) {
		Object( orientation: Gtk.Orientation.VERTICAL, spacing: 0 );
		var controls = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
		var lists = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
		var buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
		name_entry = new Gtk.Entry ();
		name_entry.placeholder_text = "Enter naming scheme";
		var naming_label = new Gtk.Label ("Naming Scheme:");
		var combo_label = new Gtk.Label ("Numbers:");
		naming_combo = new Gtk.ComboBoxText ();
		naming_combo.append_text ("1,2,3,\u2026");
		naming_combo.append_text ("01,02,03,\u2026");
		naming_combo.append_text ("001,002,003,\u2026");
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
		preview_button = new Gtk.Button.with_label ("Update Preview");
		preview_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		controls.pack_start (naming_label,false,false,0);
		controls.pack_start (name_entry,false, false, 0);
		buttons.pack_end (preview_button, false,false,0);
		controls.pack_end (naming_combo, false,false,0);
		controls.pack_end (combo_label, false,false,0);
		lists.pack_start (old_file_names, true, true, 0);
		lists.pack_end (new_file_names, true, true, 0);
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
		preview_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		new_list.clear ();
		if(name_entry.get_text ()=="") {
			for (int i = 0; i < input_files.length; i++) {
				new_list.append (out iter);
				new_list.set ( iter, 0, input_files.index(i));
			}
		}
		else{
			int index_of_char;
			string extension, file_name;
			switch (naming_combo.get_active()) {
			case  0:
				for (int i = 0; i < input_files.length; i++) {
					index_of_char = input_files.index (i).last_index_of_char ('.',0);
					extension = input_files.index (i).slice (index_of_char, input_files.index (i).length);
					new_list.append (out iter);
					file_name = name_entry.get_text ().concat ( (i+1).to_string (),extension);
					new_list.set ( iter, 0, file_name);
					output_files.append_val (file_name);
				}
				break;
			case  1:
				for (int i = 0; i < input_files.length; i++) {
					index_of_char = input_files.index (i).last_index_of_char ('.',0);
					extension = input_files.index (i).slice (index_of_char, input_files.index (i).length);
					new_list.append (out iter);
					if (i < 9)
						file_name = name_entry.get_text ().concat ("0",(i + 1).to_string (),extension);
					else
						file_name = name_entry.get_text ().concat ( (i + 1 ).to_string (),extension);
					new_list.set ( iter, 0, file_name);
					output_files.append_val (file_name);
				}
				break;
			case  2:
				for (int i = 0; i < input_files.length; i++) {
					index_of_char = input_files.index(i).last_index_of_char('.',0);
					extension = input_files.index(i).slice(index_of_char, input_files.index(i).length);
					new_list.append(out iter);
					if(i < 9)
						file_name = name_entry.get_text().concat("00",(i+1).to_string(),extension);
					else if(i < 99)
						file_name = name_entry.get_text().concat("0",(i+1).to_string(),extension);
					else
						file_name = name_entry.get_text().concat((i+1).to_string(),extension);
					new_list.set ( iter, 0, file_name);
					output_files.append_val (file_name);
				}
				break;
			}
		}
	}
}
