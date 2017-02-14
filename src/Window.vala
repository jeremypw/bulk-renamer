class Window : Gtk.Window {
	private int window_width = 200;
	private int window_height = 400;
	public Window (string[] args) {
		this.set_default_size ( window_width, window_height);
		this.set_resizable(false);
		this.set_position ( Gtk.WindowPosition.CENTER );
		this.title="Batch Renamer";
		BatchRenamer Renamer = new BatchRenamer(args);
		this.add(Renamer);
		var buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, window_width);
		Gtk.Button cancel_button = new Gtk.Button.with_label ("Cancel");
		Gtk.Button rename_button = new Gtk.Button.with_label ("Rename");
		rename_button.set_sensitive(false);
		var title = new Gtk.Label ("Bulk Rename");
		buttons.pack_start(cancel_button, true, true, 0);
		buttons.pack_start(title, false, false, 0);
		buttons.pack_end(rename_button, true,true, 0);
		rename_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		var headerbar = new Gtk.HeaderBar();
		this.set_titlebar (headerbar);
		headerbar.set_custom_title(buttons);
		buttons.border_width = 8;
		this.destroy.connect ( Gtk.main_quit );
		this.get_style_context ().add_class ("rounded");
		cancel_button.clicked.connect (() => {
            this.destroy();
	    });
		rename_button.clicked.connect (() => {
	        Renamer.rename_files();
		    this.destroy();
	    });
		Renamer.preview_button.clicked.connect (() => {
		    Renamer.update_view();
		    rename_button.set_sensitive(true);
		});
	}
	public static int main(string[] args){
		Gtk.init (ref args);
		Window renamer_window = new Window(args);
		renamer_window.show_all();
		Gtk.main ();
		return 0;
	}
}
