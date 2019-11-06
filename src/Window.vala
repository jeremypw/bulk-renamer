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
    private Renamer renamer;

    public Window (Gtk.Application app) {
        Object (
            application: app
        );
    }

    construct {
        title = _("Bulk Renamer");
        set_size_request (600, 400);
        resizable = false;

        renamer = new Renamer ();
        renamer.margin = 6;

        var header_bar = new Gtk.HeaderBar ();
        header_bar.set_title (_("Bulk Renamer"));
        header_bar.show_close_button = true;
        header_bar.has_subtitle = false;

        set_titlebar (header_bar);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.margin = 3;

        var rename_button = new Gtk.Button.with_label (_("Rename"));
        rename_button.margin = 3;
        rename_button.sensitive = false;
        renamer.bind_property ("can-rename",
                                rename_button, "sensitive",
                                GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);

        rename_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var undo_button = new Gtk.Button.with_label (_("Undo"));
        undo_button.margin = 3;
        undo_button.sensitive = false;
        renamer.bind_property ("can-undo",
                                undo_button, "sensitive",
                                GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);

        var bbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        bbox.vexpand = false;
        bbox.margin_bottom = 6;
        bbox.set_layout (Gtk.ButtonBoxStyle.END);
        bbox.add (cancel_button);
        bbox.add (rename_button);

        bbox.add (undo_button);
        bbox.set_child_secondary (undo_button, true);

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
                var dlg = new Granite.MessageDialog ("Error renaming files",
                                                     e.message,
                                                     new ThemedIcon ("dialog-error"));
                dlg.run ();
                dlg.destroy ();
            }
        });

        cancel_button.clicked.connect (() => {
            destroy ();
        });

        undo_button.clicked.connect (() => {
            renamer.undo ();
        });
    }

    public void set_files (File[] files) {
        renamer.add_files (files);
    }
}
