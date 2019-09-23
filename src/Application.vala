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
    public const OptionEntry[] RENAMER_OPTIONS =  {
        { "base-name", 'b', 0, OptionArg.STRING, out base_name,
        "Base name of renamed files", "BASE NAME" },
        { "sort-by-date", 0, 0, OptionArg.NONE, out sort_by_date,
        "Rename in date order", null },
        { "sort-by-name", 0, 0, OptionArg.NONE, out sort_by_name,
        "Rename in original name order", null },
        { "reverse_order", 'r', 0, OptionArg.NONE, out reverse_order,
        "Reverse sort order", null },
        { null }
    };


    public static string base_name;
    public static bool sort_by_date = false;
    public static bool sort_by_name = false;
    public static bool reverse_order = false;

    private BulkRenamer.Window? main_window;

   construct {
        application_id = "com.github.jeremypw.bulk-renamer";
        flags = ApplicationFlags.HANDLES_OPEN;
        Intl.setlocale (LocaleCategory.ALL, "");

        add_main_option_entries (RENAMER_OPTIONS);

        var quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.destroy ();
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
