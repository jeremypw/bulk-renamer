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

public class Modifier : Gtk.Grid {
    private Gtk.ComboBoxText naming_combo;
    private Gtk.Stack stack;
    private Gtk.Revealer revealer;
    private Gtk.SpinButton digits_spin_button;
    private Gtk.Entry number_entry;
    private Gtk.Entry search_entry;
    private Gtk.Entry replace_entry;

    public signal void changed ();

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        column_spacing = 6;

        naming_combo = new Gtk.ComboBoxText ();
        naming_combo.insert (RenameMode.NUMBER, null, RenameMode.NUMBER.to_string ());
        naming_combo.insert (RenameMode.DATETIME, null, RenameMode.DATETIME.to_string ());
        naming_combo.insert (RenameMode.REPLACE, null, RenameMode.REPLACE.to_string ());
        naming_combo.active = 0;

        var digits_grid = new Gtk.Grid ();
        digits_grid.orientation = Gtk.Orientation.HORIZONTAL;
        digits_grid.column_spacing = 6;

        var digits_label = new Gtk.Label (_("Digits"));
        digits_spin_button = new Gtk.SpinButton.with_range (0.0, 5.0, 1.0);
        digits_spin_button.digits = 1;
        digits_spin_button.set_value (1.0);

        number_entry = new Gtk.Entry ();
        number_entry.placeholder_text = _("Start from (default 1)");
        number_entry.hexpand = true;

        digits_grid.add (digits_label);
        digits_grid.add (digits_spin_button);
        digits_grid.add (number_entry);
//        digits_grid.hexpand = true;

        search_entry = new Gtk.Entry ();
        search_entry.placeholder_text = _("Search text");

        replace_entry = new Gtk.Entry ();
        replace_entry.placeholder_text = _("Replacement text");

        var search_replace_grid = new Gtk.Grid ();
        search_replace_grid.column_spacing = 6;

        search_replace_grid.orientation = Gtk.Orientation.HORIZONTAL;
        search_replace_grid.add (search_entry);
        search_replace_grid.add (replace_entry);

        stack = new Gtk.Stack ();
        stack.add_named (digits_grid, "NUMBER");
        stack.add_named (search_replace_grid, "REPLACE");
        stack.set_visible_child_name ("NUMBER");

        revealer = new Gtk.Revealer ();
        revealer.add (stack);
        revealer.reveal_child = true;

        add (naming_combo);
        add (revealer);

        show_all ();

        naming_combo.changed.connect (change_rename_mode);

        number_entry.focus_out_event.connect (() => {
            changed ();
            return Gdk.EVENT_PROPAGATE;
        });

        number_entry.activate.connect (() => {
            changed ();
        });
    }

   public void change_rename_mode () {
        if (naming_combo.get_active () == RenameMode.DATETIME) {
            revealer.reveal_child = false;
        } else if (naming_combo.get_active () == RenameMode.REPLACE) {
            revealer.reveal_child = true;
            stack.set_visible_child_name ("REPLACE");
        } else {
            revealer.reveal_child = true;
            stack.set_visible_child_name ("NUMBER");
        }

        changed ();
    }
}