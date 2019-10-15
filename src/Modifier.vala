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
    private Gtk.ComboBoxText position_combo;
    private Gtk.ComboBoxText naming_combo;
    private Gtk.Stack stack;
    private Gtk.Revealer revealer;
    private Gtk.Revealer search_revealer;
    private Gtk.SpinButton digits_spin_button;
    private Gtk.Entry number_entry;
    private Gtk.Entry text_entry;
    private Gtk.Entry search_entry;

    public signal void changed ();

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        column_spacing = 6;

        position_combo = new Gtk.ComboBoxText ();
        position_combo.insert (RenamePosition.SUFFIX, "NUMBER", RenamePosition.SUFFIX.to_string ());
        position_combo.insert (RenamePosition.PREFIX, "TEXT", RenamePosition.PREFIX.to_string ());
        position_combo.insert (RenamePosition.REPLACE, "DATETIME", RenamePosition.REPLACE.to_string ());
        position_combo.active = RenamePosition.SUFFIX;

        search_revealer = new Gtk.Revealer ();
        search_entry = new Gtk.Entry ();
        search_entry.placeholder_text = _("Target text");
        search_revealer.add (search_entry);
        search_revealer.reveal_child = false;

        var position_grid = new Gtk.Grid ();
        position_grid.orientation = Gtk.Orientation.HORIZONTAL;
        position_grid.column_spacing = 6;
        position_grid.add (search_revealer);
        position_grid.add (position_combo);

        naming_combo = new Gtk.ComboBoxText ();
        naming_combo.insert (RenameMode.NUMBER, "NUMBER", RenameMode.NUMBER.to_string ());
        naming_combo.insert (RenameMode.TEXT, "TEXT", RenameMode.TEXT.to_string ());
        naming_combo.insert (RenameMode.DATETIME, "DATETIME", RenameMode.DATETIME.to_string ());
        naming_combo.active = RenameMode.NUMBER;

        text_entry = new Gtk.Entry ();
        text_entry.hexpand = true;

        var digits_label = new Gtk.Label (_("Digits"));
        digits_spin_button = new Gtk.SpinButton.with_range (0.0, 5.0, 1.0);
        digits_spin_button.digits = 1;
        digits_spin_button.set_value (1.0);

        number_entry = new Gtk.Entry ();
        number_entry.placeholder_text = _("Number from ");
        number_entry.hexpand = true;

        var digits_grid = new Gtk.Grid ();
        digits_grid.orientation = Gtk.Orientation.HORIZONTAL;
        digits_grid.column_spacing = 6;
        digits_grid.add (digits_label);
        digits_grid.add (digits_spin_button);
        digits_grid.add (number_entry);

        stack = new Gtk.Stack ();
        stack.add_named (digits_grid, "NUMBER");
        stack.add_named (text_entry, "TEXT");
        stack.set_visible_child_name ("NUMBER");

        revealer = new Gtk.Revealer ();
        revealer.add (stack);
        revealer.reveal_child = true;

        add (naming_combo);
        add (revealer);
        add (position_grid);

        show_all ();

        naming_combo.changed.connect (change_rename_mode);
        position_combo.changed.connect (change_rename_position);

        number_entry.focus_out_event.connect (() => {
            schedule_update ();
            return Gdk.EVENT_PROPAGATE;
        });

        number_entry.activate.connect (() => {
            changed ();
        });

        search_entry.focus_out_event.connect (() => {
            schedule_update ();
            return Gdk.EVENT_PROPAGATE;
        });

        search_entry.activate.connect (() => {
            schedule_update ();
        });

        text_entry.focus_out_event.connect (() => {
            if (text_entry.text != "") {
                schedule_update ();
            }

            return Gdk.EVENT_PROPAGATE;
        });

        text_entry.activate.connect (() => {
            if (text_entry.text != "") {
                schedule_update ();
            }
        });

        digits_spin_button.value_changed.connect (schedule_update);

        position_combo.changed.connect (() => {
            text_entry.placeholder_text = ((RenamePosition)(position_combo.get_active ())).to_string ();
            schedule_update ();
        });
    }

   public void change_rename_mode () {
        switch (naming_combo.get_active ()) {
            case RenameMode.DATETIME:
                revealer.reveal_child = false;
                break;

            case RenameMode.TEXT:
                revealer.reveal_child = true;
                stack.set_visible_child_name ("TEXT");
                break;

            default:
                revealer.reveal_child = true;
                stack.set_visible_child_name ("NUMBER");
                break;
        }

        schedule_update ();
    }

   public void change_rename_position () {
        search_revealer.reveal_child = position_combo.get_active () == RenamePosition.REPLACE;
        schedule_update ();
    }

    public string rename (string input, int index) {
        var seq = index + int.parse (number_entry.text);
        string new_text = "";

        switch (naming_combo.get_active ()) {
            case RenameMode.NUMBER:
                var template = "%%0%id".printf ((int)(digits_spin_button.get_value ()));
                new_text = template.printf (seq);
                break;

            case RenameMode.TEXT:
                new_text = text_entry.text;
                break;

            case RenameMode.DATETIME:
                var dt = new GLib.DateTime.now_local ();
                new_text = dt.format ("%Y-%m-%d");
                break;

            default:
                break;
        }

        switch (position_combo.get_active ()) {
            case RenamePosition.SUFFIX:
                return input.concat ("-", new_text);

            case RenamePosition.PREFIX:
                return new_text.concat ("-", input);

            case RenamePosition.REPLACE:
                return input.replace (search_entry.text, new_text);

            default:
                break;
        }

        return input;
    }

    private void schedule_update () {
        /*TODO throttle updating */
        changed ();
    }
}