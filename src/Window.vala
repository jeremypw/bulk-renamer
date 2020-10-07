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
    public const string ACTION_OPEN = "action-open";
    public const string ACTION_UNDO = "action-undo";
    public const string ACTION_CLEAR_FILES = "action-clear-files";
    public const string ACTION_RESET = "action-reset";
    public const string ACTION_RESTORE = "action-restore";
    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_OPEN, action_open },
        { ACTION_UNDO, action_undo },
        { ACTION_CLEAR_FILES, action_clear_files },
        { ACTION_RESET, action_reset },
        { ACTION_RESTORE, action_restore }
    };

    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();
    private static Settings app_settings;

    static construct {
        app_settings = BulkRenamer.App.app_settings;

        action_accelerators.set (ACTION_OPEN, "<Control>o");
        action_accelerators.set (ACTION_UNDO, "<Control>z");
        action_accelerators.set (ACTION_CLEAR_FILES, "<Control>Delete");
        action_accelerators.set (ACTION_RESET, "<Control>X");
        action_accelerators.set (ACTION_RESTORE, "<Control>R");
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
        open_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

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
            quit ();
        });

        delete_event.connect (() => {
            quit ();
        });

        undo_button.clicked.connect (() => {
            renamer.undo ();
        });

        if (BulkRenamer.App.restore) {
            action_restore ();
        } else {
            if (BulkRenamer.App.base_name != "") {
                renamer.set_custom_base_name (BulkRenamer.App.base_name);
            }

            if (BulkRenamer.App.sort_by_created) {
                renamer.set_sort_order (RenameSortBy.CREATED, BulkRenamer.App.sort_reversed);
            } else if (BulkRenamer.App.sort_by_modified) {
                renamer.set_sort_order (RenameSortBy.MODIFIED, BulkRenamer.App.sort_reversed);
            } else {
                renamer.set_sort_order (RenameSortBy.NAME, BulkRenamer.App.sort_reversed);
            }
        }

        var state = app_settings.get_enum ("window-state");

        switch (state) {
            case 1:
                maximize ();
                break;
            default:
                int default_x, default_y;
                app_settings.get ("window-position", "(ii)", out default_x, out default_y);

                if (default_x != -1 && default_y != -1) {
                    move (default_x, default_y);
                }

                break;
        }
    }

    private void action_restore () {
        renamer.set_base_type (app_settings.get_enum ("base-type"));
        renamer.set_custom_base_name (app_settings.get_string ("custom-base"));

        /* Restore modifiers */
        renamer.clear_mods ();
        Variant mod_vars = app_settings.get_value ("modifier-list"); // Type "av"
        var iter = new VariantIter (mod_vars);

        Variant mod_var;

        int count = 0;
        while (iter.next ("v", out mod_var)) {
            if (count == 0) {
                renamer.modifier_chain[0].set_from_variant (mod_var);
            } else {
                renamer.add_modifier (true).set_from_variant (mod_var);
            }

            count++;
        }

        debug ("%i modifiers restored", count);

        var sort = (RenameSortBy)(app_settings.get_enum ("sort-by"));
        var reversed = app_settings.get_boolean ("reversed");

        renamer.set_sort_order (sort, reversed);
        renamer.set_protect_extension (app_settings.get_boolean ("protect-extension"));
    }

    private void action_reset () {
        /* LAZY - this is easier than retrieving defaults from settings */
        renamer.set_base_type (0);
        renamer.set_custom_base_name ("");

        renamer.clear_mods ();

        renamer.set_sort_order (0, false);
        renamer.set_protect_extension (true);
    }

    public void set_files (File[] files) {
        renamer.add_files (files);
    }

    private void action_open () {
        var filechooser = new Gtk.FileChooserNative (
            "Select files to rename", this, Gtk.FileChooserAction.OPEN, _("Select"), _("Cancel")
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
        renamer.undo ();
    }

    private void action_clear_files () {
        renamer.clear_files ();
    }

    public void quit () {
        /* Save window state */
        var state = get_window ().get_state ();
        if (Gdk.WindowState.MAXIMIZED in state) {
            app_settings.set_enum ("window-state", 1);
        } else {
            app_settings.set_enum ("window-state", 0);
        }

        // Save window position
        int x, y;
        get_position (out x, out y);
        app_settings.set ("window-position", "(ii)", x, y);

        /* Save basename */
        app_settings.set_enum ("base-type", renamer.get_base_type ());
        app_settings.set_string ("custom-base", renamer.get_custom_base_name ());

        /* Save protect extension */
        app_settings.set_boolean ("protect-extension", renamer.get_protect_extension ());
        /* Save modifier settings */
        var vb = new VariantBuilder (new VariantType ("av"));
        foreach (var modifier in renamer.modifier_chain) {
            vb.add ("v", modifier.to_variant ());
        }

        app_settings.set_value ("modifier-list", vb.end ());

        /* Save sort type */
        app_settings.set_enum ("sort-by", renamer.get_sort_type ());
        app_settings.set_boolean ("reversed", renamer.get_reverse_sort ());

        destroy ();
    }
}
