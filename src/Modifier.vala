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

public class Modifier : Gtk.ListBoxRow {
    private Gtk.ComboBoxText position_combo;
    private Gtk.ComboBoxText mode_combo;
    private Gtk.ComboBoxText date_format_combo;
    private Gtk.ComboBoxText date_type_combo;
    private Granite.Widgets.DatePicker date_picker;
    private Gtk.Stack mode_stack;
    private Gtk.Stack position_stack;
    private Gtk.SpinButton digits_spin_button;
    private Gtk.SpinButton start_number_spin_button;
    private Gtk.Entry text_entry;
    private Gtk.Entry separator_entry;
    private Gtk.Entry search_entry;
    private Gtk.Revealer remove_revealer;
    private Gtk.Revealer date_picker_revealer;

    public bool allow_remove { get; set; }

    public signal void remove_request ();
    public signal void update_request ();

    construct {
        margin_top = 3;
        margin_bottom = 3;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.column_spacing = 12;

        mode_combo = new Gtk.ComboBoxText ();
        mode_combo.valign = Gtk.Align.CENTER;
        mode_combo.insert (RenameMode.TEXT, "TEXT", RenameMode.TEXT.to_string ());
        mode_combo.insert (RenameMode.NUMBER, "NUMBER", RenameMode.NUMBER.to_string ());
        mode_combo.insert (RenameMode.DATETIME, "DATETIME", RenameMode.DATETIME.to_string ());

        text_entry = new Gtk.Entry ();
        text_entry.set_max_width_chars (64);
        text_entry.vexpand = false;
        text_entry.hexpand = false;

        var start_number_label = new Gtk.Label (_("Start Number"));
        start_number_spin_button = new Gtk.SpinButton.with_range (0, int.MAX, 1);
        start_number_spin_button.digits = 0;
        start_number_spin_button.set_value (0.0);

        var digits_label = new Gtk.Label (_("Digits"));
        digits_spin_button = new Gtk.SpinButton.with_range (0, 5, 1);
        digits_spin_button.digits = 0;
        digits_spin_button.set_value (1.0);

        var digits_grid = new Gtk.Grid ();
        digits_grid.orientation = Gtk.Orientation.HORIZONTAL;
        digits_grid.column_spacing = 6;
        digits_grid.add (start_number_label);
        digits_grid.add (start_number_spin_button);
        digits_grid.add (digits_label);
        digits_grid.add (digits_spin_button);

        date_format_combo = new Gtk.ComboBoxText ();
        date_format_combo.valign = Gtk.Align.CENTER;
        date_format_combo.insert (RenameDateFormat.DEFAULT_DATE, "DEFAULT_DATE",
                                  RenameDateFormat.DEFAULT_DATE.to_string ());

        date_format_combo.insert (RenameDateFormat.DEFAULT_DATETIME, "DEFAULT_DATETIME",
                                  RenameDateFormat.DEFAULT_DATETIME.to_string ());

        date_format_combo.insert (RenameDateFormat.LOCALE, "LOCALE",
                                  RenameDateFormat.LOCALE.to_string ());

        date_format_combo.insert (RenameDateFormat.ISO_DATE, "ISO_DATE",
                                  RenameDateFormat.ISO_DATE.to_string ());

        date_format_combo.insert (RenameDateFormat.ISO_DATETIME, "ISO_DATETIME",
                                  RenameDateFormat.ISO_DATETIME.to_string ());

        date_type_combo = new Gtk.ComboBoxText ();
        date_type_combo.valign = Gtk.Align.CENTER;
        date_type_combo.insert (RenameDateType.NOW, "NOW", RenameDateType.NOW.to_string ());
        date_type_combo.insert (RenameDateType.CHOOSE, "CHOOSE", RenameDateType.CHOOSE.to_string ());

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
        mode_stack.set_homogeneous (false);
        mode_stack.vexpand = false;
        mode_stack.hexpand = false;

        mode_stack.add_named (digits_grid, "NUMBER");
        mode_stack.add_named (text_entry, "TEXT");
        mode_stack.add_named (date_time_grid, "DATETIME");
        mode_stack.set_visible_child_name ("NUMBER");

        separator_entry = new Gtk.Entry ();
        separator_entry.placeholder_text = _("Separator");
        separator_entry.text = "";
        var separator_label = new Gtk.Label (_("Separator:"));
        separator_label.hexpand = true;
        separator_label.halign = Gtk.Align.END;

        var separator_grid = new Gtk.Grid ();
        separator_grid.margin_start = 12;
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
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        remove_button.halign = Gtk.Align.END;
        remove_button.valign = Gtk.Align.CENTER;
        remove_button.set_tooltip_text (_("Remove this modification"));

        remove_revealer = new Gtk.Revealer ();
        remove_revealer.add (remove_button);

        grid.add (mode_combo);
        grid.add (mode_stack);
        grid.add (position_grid);
        grid.add (remove_revealer);

        add (grid);

        show_all ();

        mode_combo.changed.connect (change_rename_mode);
        position_combo.changed.connect (change_rename_position);

        date_format_combo.changed.connect (() => {
            update_request ();
        });

        date_type_combo.changed.connect (() => {
            date_picker_revealer.reveal_child = date_type_combo.get_active () == RenameDateType.CHOOSE;
            if (date_type_combo.get_active () == RenameDateType.NOW) {
                update_request ();
            }
        });

        date_picker.date_changed.connect (() => {
            update_request ();
        });

        digits_spin_button.value_changed.connect (() => {
            update_request ();
        });

        start_number_spin_button.value_changed.connect (() => {
            update_request ();
        });

        search_entry.focus_out_event.connect (() => {
            update_request ();
            return Gdk.EVENT_PROPAGATE;
        });

        search_entry.activate.connect (() => {
            update_request ();
        });

        text_entry.focus_out_event.connect (() => {
            if (text_entry.text != "") {
                update_request ();
            }

            return Gdk.EVENT_PROPAGATE;
        });

        text_entry.activate.connect (() => {
            if (text_entry.text != "") {
                update_request ();
            }
        });

        separator_entry.focus_out_event.connect (() => {
            update_request ();
            return Gdk.EVENT_PROPAGATE;
        });

        separator_entry.activate.connect (() => {
            update_request ();
        });

        position_combo.changed.connect (() => {
            text_entry.placeholder_text = ((RenamePosition)(position_combo.get_active ())).to_string ();
            update_request ();
        });

        remove_button.clicked.connect (() => {
            remove_request ();
        });

        reset ();
    }

    public void reset () {
        mode_combo.active = RenameMode.TEXT;
        text_entry.text = "";
        separator_entry.text = "";
        search_entry.text = "";

        date_format_combo.set_active (RenameDateFormat.DEFAULT_DATE);
        date_type_combo.set_active (RenameDateType.NOW);
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

        update_request ();
    }

   public void change_rename_position () {
        if (position_combo.get_active () == RenamePosition.REPLACE) {
            position_stack.visible_child_name = "TARGET";
        } else {
            position_stack.visible_child_name = "SEPARATOR";
        }

        update_request ();
    }

    public string rename (string input, int index) {
        var seq = index + (int)(start_number_spin_button.get_value ());
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
}
