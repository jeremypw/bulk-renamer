/*
 * Copyright (C) 2010-2017  Vartan Belavejian
 * Copyright (C) 2019-2020  Jeremy Wootten
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
    public SimpleActionGroup actions { get; construct; }
    public const string ACTION_PREFIX = "win.";
    public const string ACTION_OPEN = "action_open";
    public const string ACTION_UNDO = "action_undo";
    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_OPEN, action_open },
        { ACTION_UNDO, action_undo }
    };

    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();
    static construct {
        action_accelerators.set (ACTION_OPEN, "<Control>o");
        action_accelerators.set (ACTION_UNDO, "<Control>z");
    }

    public Window (Gtk.Application app) {
        Object (
            application: app
        );
    }

    construct {
        actions = new SimpleActionGroup ();
        actions.add_action_entries (ACTION_ENTRIES, this);
        insert_action_group ("win", actions);

        foreach (var action in action_accelerators.get_keys ()) {
            var accels_array = action_accelerators[action].to_array ();
            accels_array += null;

            ((Gtk.Application)Application.get_default ()).set_accels_for_action (ACTION_PREFIX + action, accels_array);
        }

        title = _("Bulk Renamer");
        set_default_size (600, 400);

        renamer = new Renamer ();
        renamer.margin = 12;

        var header_bar = new Gtk.HeaderBar () {
            title = _("Bulk Renamer"),
            show_close_button = true,
            has_subtitle = false
        };

        var open_button = new Gtk.Button.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR);
        open_button.action_name = ACTION_PREFIX + ACTION_OPEN;
        open_button.tooltip_markup = Granite.markup_accel_tooltip (
            application.get_accels_for_action (open_button.action_name),
            _("Select files to rename")
        );

        header_bar.pack_start (open_button);

        set_titlebar (header_bar);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.margin = 6;

        var rename_button = new Gtk.Button.with_label (_("Rename"));
        rename_button.margin = 6;
        rename_button.sensitive = false;
        renamer.bind_property ("can-rename",
                                rename_button, "sensitive",
                                GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);

        rename_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var undo_button = new Gtk.Button.with_label (_("Undo"));
        undo_button.margin = 6;
        undo_button.sensitive = false;
        renamer.bind_property ("can-undo",
                                undo_button, "sensitive",
                                GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);

        var bbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        bbox.vexpand = false;
        bbox.margin_bottom = 6;
        bbox.margin_start = 18;
        bbox.margin_end = 18;
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

        renamer.set_base_name (BulkRenamer.App.base_name);

        if (BulkRenamer.App.sort_by_created) {
            renamer.set_sort_order (RenameSortBy.CREATED, BulkRenamer.App.sort_reversed);
        } else if (BulkRenamer.App.sort_by_modified) {
            renamer.set_sort_order (RenameSortBy.MODIFIED, BulkRenamer.App.sort_reversed);
        } else {
            renamer.set_sort_order (RenameSortBy.NAME, BulkRenamer.App.sort_reversed);
        }
    }

    public void set_files (File[] files) {
        renamer.add_files (files);
    }

    private void action_open () {
        var filechooser = new Gtk.FileChooserNative (
            "Select files to rename",  this, Gtk.FileChooserAction.OPEN, _("Select"), _("Cancel")
        ) {
            select_multiple = true,
            modal = true
        };

        var response = filechooser.run ();
        if (response == Gtk.ResponseType.ACCEPT) {

        }

        var selected_files_list = filechooser.get_files ();
        var selected_files_array = new File[selected_files_list.length ()];
        int index = 0;
        selected_files_list.@foreach ((file) => {
            selected_files_array[index++] = file.dup ();
        });

        set_files (selected_files_array);

        filechooser.destroy ();
    }

    private void action_undo () {

    }
}
