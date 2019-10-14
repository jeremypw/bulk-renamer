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
        renamer = new Renamer ();
        renamer.margin = 6;

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.margin = 3;

        var rename_button = new Gtk.Button.with_label (_("Rename"));
        rename_button.margin = 3;
        rename_button.sensitive = false;
        renamer.bind_property ("can-rename", rename_button, "sensitive", GLib.BindingFlags.DEFAULT);
        rename_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        
        var bbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        bbox.set_layout (Gtk.ButtonBoxStyle.END);
        bbox.add (cancel_button);
        bbox.add (rename_button);

        var headerbar = new Gtk.HeaderBar ();
        headerbar.set_title ("Bulk Rename");
        set_titlebar (headerbar);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (renamer);
        grid.add (bbox);

        add (grid);
        show_all ();

        rename_button.clicked.connect (() => {
            try {
                renamer.rename_files ();
            } catch (Error e) {
                var dlg = new Granite.MessageDialog ("Error renaming files", e.message, new ThemedIcon ("dialog-error"));
                dlg.run ();
                dlg.destroy ();
            }
        });

        cancel_button.clicked.connect (() => {
            destroy ();
        });
    }

    public void set_files (File[] files) {
        renamer.add_files (files);
    }
}
