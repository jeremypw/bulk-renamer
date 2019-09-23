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

public class BulkRenamer.Window : Gtk.ApplicationWindow {
    private const int WIDTH = 200;
    private const int HEIGHT = 400;
    private Renamer renamer;

    public Window (Gtk.Application app) {
        Object (
            application: app
        );
    }

    construct {
        set_default_size (WIDTH, HEIGHT);
        set_resizable (false);
        set_position ( Gtk.WindowPosition.CENTER );

        renamer = new Renamer ();
        add (renamer);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var rename_button = new Gtk.Button.with_label (_("Rename"));
        rename_button.sensitive = false;
        rename_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var title = new Gtk.Label ("Bulk Rename");
        var buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, WIDTH);
        buttons.border_width = 8;
        buttons.pack_start (cancel_button, true, true, 0);
        buttons.pack_start (title, false, false, 0);
        buttons.pack_end (rename_button, true, true, 0);

        var headerbar = new Gtk.HeaderBar ();
        headerbar.set_custom_title (buttons);
        set_titlebar (headerbar);

        cancel_button.clicked.connect (() => {
            destroy ();
        });

        rename_button.clicked.connect (() => {
            try {
                renamer.rename_files ();
                destroy ();
            } catch (Error e) {
                var dlg = new Granite.MessageDialog ("Error renaming files", e.message, new ThemedIcon ("dialog-error"));
                dlg.run ();
                dlg.destroy ();
            }
        });

        renamer.preview_button.clicked.connect (() => {
            renamer.update_view ();
            rename_button.set_sensitive (true);
        });
    }

    public void set_files (File[] files) {
        renamer.add_files (files);
    }
}
