/*
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
 *  Jeremy Wootten <jeremywootten@gmail.com>
 *
*/

public class BulkRenamer.App : Gtk.Application {
    public const OptionEntry[] RENAMER_OPTIONS = {
        { "base-name", 'b', 0, OptionArg.STRING, out base_name,
        "Base name of renamed files", "BASE NAME" },
        { "sort-by-created", 'c', 0, OptionArg.NONE, out sort_by_created,
        "Rename in creation date order", null },
        { "sort-by-modified", 'm', 0, OptionArg.NONE, out sort_by_modified,
        "Rename in modification date order", null },
        { "reverse_order", 'r', 0, OptionArg.NONE, out sort_reversed,
        "Reverse sort order", null },
        { null }
    };


    public static string? base_name = null;
    public static bool sort_by_created = false;
    public static bool sort_by_modified = false;
    public static bool sort_reversed = false;
    public static string[] file_names = {};
    public static bool restore = true;
    public static Settings app_settings;

    private BulkRenamer.Window? main_window;

    static construct {
        app_settings = new Settings ("io.github.jeremypw.bulk-renamer");
    }

   construct {
        application_id = "com.github.jeremypw.bulk-renamer";
        set_option_context_summary (N_("Rename files according to rules"));
        set_option_context_description (N_("""
The rules used for renaming are chosen through an application window.
Numbers, dates or text may be added before or after the name, with a chosen separator.
The whole of, or parts of, the original name may be replaced.
Several rules may be applied sequentially.
The results are previewed before committing to renaming.
It is possible to undo the last renaming while the window is open.
"""));

        set_option_context_parameter_string (N_("[FILES]"));
        flags = ApplicationFlags.HANDLES_OPEN;
        Intl.setlocale (LocaleCategory.ALL, "");

        add_main_option_entries (RENAMER_OPTIONS);

        var quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.quit ();
            }
        });

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q"});
    }

    public override void open (File[] files, string hint) {
        activate ();

        if (main_window != null) {
            main_window.set_files (files);
        }

    }

    public override void activate () {
        /* Command line options used do not restore settings */
        App.restore = !(
            base_name != null ||
            sort_by_created ||
            sort_by_modified ||
            sort_reversed
        );

        if (main_window == null) {
            main_window = new BulkRenamer.Window (this);

            main_window.destroy.connect (() => {
                main_window = null;
            });

            add_window (main_window);
            main_window.show_all ();
        }

        main_window.present ();
    }
}

public static int main (string[] args) {
    var application = new BulkRenamer.App ();
    return application.run (args);
}
