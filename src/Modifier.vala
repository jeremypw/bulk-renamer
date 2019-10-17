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
    private Gtk.ComboBoxText mode_combo;
    private Gtk.ComboBoxText date_format_combo;
    private Gtk.ComboBoxText date_type_combo;
    private Granite.Widgets.DatePicker date_picker;
    private Gtk.Stack mode_stack;
    private Gtk.Stack position_stack;
    private Gtk.SpinButton digits_spin_button;
    private Gtk.Entry number_entry;
    private Gtk.Entry text_entry;
    private Gtk.Entry separator_entry;
    private Gtk.Entry search_entry;
    private Gtk.Revealer remove_revealer;
    private Gtk.Revealer date_picker_revealer;

    public bool allow_remove { get; set; }

    public signal void changed ();
    public signal void remove_request ();

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        column_spacing = 6;

        mode_combo = new Gtk.ComboBoxText ();
        mode_combo.valign = Gtk.Align.CENTER;
        mode_combo.insert (RenameMode.NUMBER, "NUMBER", RenameMode.NUMBER.to_string ());
        mode_combo.insert (RenameMode.TEXT, "TEXT", RenameMode.TEXT.to_string ());
        mode_combo.insert (RenameMode.DATETIME, "DATETIME", RenameMode.DATETIME.to_string ());
        mode_combo.active = RenameMode.NUMBER;

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

        date_format_combo = new Gtk.ComboBoxText ();
        date_format_combo.valign = Gtk.Align.CENTER;
        date_format_combo.insert (RenameDateFormat.DEFAULT_DATE, "DEFAULT_DATE", RenameDateFormat.DEFAULT_DATE.to_string ());
        date_format_combo.insert (RenameDateFormat.DEFAULT_DATETIME, "DEFAULT_DATETIME", RenameDateFormat.DEFAULT_DATETIME.to_string ());
        date_format_combo.insert (RenameDateFormat.LOCALE, "LOCALE", RenameDateFormat.LOCALE.to_string ());
        date_format_combo.insert (RenameDateFormat.ISO_DATE, "ISO_DATE", RenameDateFormat.ISO_DATE.to_string ());
        date_format_combo.insert (RenameDateFormat.ISO_DATETIME, "ISO_DATETIME", RenameDateFormat.ISO_DATETIME.to_string ());
        date_format_combo.set_active (RenameDateFormat.DEFAULT_DATE);

        date_type_combo = new Gtk.ComboBoxText ();
        date_type_combo.valign = Gtk.Align.CENTER;
        date_type_combo.insert (RenameDateType.NOW, "NOW", RenameDateType.NOW.to_string ());
        date_type_combo.insert (RenameDateType.CHOOSE, "CHOOSE", RenameDateType.CHOOSE.to_string ());
        date_type_combo.set_active (RenameDateType.NOW);

        date_picker = new Granite.Widgets.DatePicker ();
        date_picker_revealer = new Gtk.Revealer ();
        date_picker_revealer.add (date_picker);
        date_picker_revealer.reveal_child = false;

        var date_time_grid = new Gtk.Grid ();
        date_time_grid.orientation = Gtk.Orientation.HORIZONTAL;
        date_time_grid.column_spacing = 6;
        date_time_grid.add (date_format_combo);
        date_time_grid.add (date_type_combo);
        date_time_grid.add (date_picker_revealer);

        mode_stack = new Gtk.Stack ();
        mode_stack.valign = Gtk.Align.CENTER;
        mode_stack.add_named (digits_grid, "NUMBER");
        mode_stack.add_named (text_entry, "TEXT");
        mode_stack.add_named (date_time_grid, "DATETIME");
        mode_stack.set_visible_child_name ("NUMBER");

        separator_entry = new Gtk.Entry ();
        separator_entry.placeholder_text = _("Separator");
        separator_entry.text = "-";
        var separator_label = new Gtk.Label (_("Separator:"));

        var separator_grid = new Gtk.Grid ();
        separator_grid.orientation = Gtk.Orientation.HORIZONTAL;
        separator_grid.column_spacing = 6;
        separator_grid.add (separator_label);
        separator_grid.add (separator_entry);

        search_entry = new Gtk.Entry ();
        search_entry.placeholder_text = _("Target text");

        position_stack = new Gtk.Stack ();
        position_stack.valign = Gtk.Align.CENTER;
        position_stack.add_named (separator_grid, "SEPARATOR");
        position_stack.add_named (search_entry, "TARGET");

        position_combo = new Gtk.ComboBoxText ();
        position_combo.insert (RenamePosition.SUFFIX, "NUMBER", RenamePosition.SUFFIX.to_string ());
        position_combo.insert (RenamePosition.PREFIX, "TEXT", RenamePosition.PREFIX.to_string ());
        position_combo.insert (RenamePosition.REPLACE, "DATETIME", RenamePosition.REPLACE.to_string ());
        position_combo.active = RenamePosition.SUFFIX;

        var position_grid = new Gtk.Grid ();
        position_grid.orientation = Gtk.Orientation.HORIZONTAL;
        position_grid.column_spacing = 6;
        position_grid.valign = Gtk.Align.CENTER;
        position_grid.add (position_stack);
        position_grid.add (position_combo);

        var remove_button = new Gtk.Button.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        remove_button.halign = Gtk.Align.END;
        remove_button.margin = 6;
        remove_button.valign = Gtk.Align.CENTER;
        remove_button.set_tooltip_text (_("Remove this modification"));

        remove_revealer = new Gtk.Revealer ();
        remove_revealer.add (remove_button);

        add (mode_combo);
        add (mode_stack);
        add (position_grid);
        add (remove_revealer);

        show_all ();

        mode_combo.changed.connect (change_rename_mode);
        position_combo.changed.connect (change_rename_position);

        date_format_combo.changed.connect (schedule_update);
        date_type_combo.changed.connect (() => {
            date_picker_revealer.reveal_child = date_type_combo.get_active () == RenameDateType.CHOOSE;
            if (date_type_combo.get_active () == RenameDateType.NOW) {
                schedule_update ();
            }
        });

        date_picker.date_changed.connect (() => {
            schedule_update ();
        });

        number_entry.focus_out_event.connect (() => {
            schedule_update ();
            return Gdk.EVENT_PROPAGATE;
        });

        number_entry.activate.connect (() => {
            schedule_update ();
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

        separator_entry.focus_out_event.connect (() => {
            schedule_update ();
            return Gdk.EVENT_PROPAGATE;
        });

        separator_entry.activate.connect (() => {
            schedule_update ();
        });

        digits_spin_button.value_changed.connect (schedule_update);

        position_combo.changed.connect (() => {
            text_entry.placeholder_text = ((RenamePosition)(position_combo.get_active ())).to_string ();
            schedule_update ();
        });

        remove_button.clicked.connect (() => {
            remove_request ();
        });
    }

    public Modifier (bool _allow_remove) {
        Object (allow_remove: _allow_remove);
        remove_revealer.reveal_child = allow_remove;
    }

    public void change_rename_mode () {
        switch (mode_combo.get_active ()) {
            case RenameMode.NUMBER:
                mode_stack.set_visible_child_name ("NUMBER");
                break;

            case RenameMode.TEXT:
                mode_stack.set_visible_child_name ("TEXT");
                break;

            case RenameMode.DATETIME:
                mode_stack.set_visible_child_name ("DATETIME");
                break;

            default:
                break;
        }

        schedule_update ();
    }

   public void change_rename_position () {
        if (position_combo.get_active () == RenamePosition.REPLACE) {
            position_stack.visible_child_name = "TARGET";
        } else {
            position_stack.visible_child_name = "SEPARATOR";
        }

        schedule_update ();
    }

    public string rename (string input, int index) {
        var seq = index + int.parse (number_entry.text);
        string new_text = "";

        switch (mode_combo.get_active ()) {
            case RenameMode.NUMBER:
                var template = "%%0%id".printf ((int)(digits_spin_button.get_value ()));
                new_text = template.printf (seq);
                break;

            case RenameMode.TEXT:
                new_text = text_entry.text;
                break;

            case RenameMode.DATETIME:
                GLib.DateTime dt;
                switch (date_type_combo.get_active ()) {
                    case RenameDateType.NOW:
                        dt = new GLib.DateTime.now_local ();
                        break;
                    case RenameDateType.CHOOSE:
                        dt = date_picker.date;
                        break;
                    default:
                        assert_not_reached ();
                }

                new_text = get_formated_date_time (dt);

                break;

            default:
                break;
        }

        switch (position_combo.get_active ()) {
            case RenamePosition.SUFFIX:
                return input.concat (separator_entry.text, new_text);

            case RenamePosition.PREFIX:
                return new_text.concat (separator_entry.text, input);

            case RenamePosition.REPLACE:
                return input.replace (search_entry.text, new_text);

            default:
                break;
        }

        return input;
    }

    public string get_formated_date_time (DateTime? dt) {
        switch (date_format_combo.get_active ()) {
            case RenameDateFormat.DEFAULT_DATE:
                return dt.format (Granite.DateTime.get_default_date_format (false, true, true));

            case RenameDateFormat.DEFAULT_DATETIME:
                return dt.format (Granite.DateTime.get_default_date_format (false, true, true).
                                  concat (" ", Granite.DateTime.get_default_time_format ()));

            case RenameDateFormat.LOCALE:
                return dt.format ("%c");

            case RenameDateFormat.ISO_DATE:
                return dt.format ("%Y-%m-%d");

            case RenameDateFormat.ISO_DATETIME:
                return dt.format ("%Y-%m-%d %H:%M:%S");

            default:
                assert_not_reached ();
        }
    }

    private void schedule_update () {
        /*TODO throttle updating */
        changed ();
    }
}
