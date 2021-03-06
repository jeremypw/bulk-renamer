/*
 * Copyright (C) 2019-2020      Jeremy Wootten
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
    private Granite.Widgets.DatePicker date_picker;
    private Granite.Widgets.TimePicker time_picker;
    private Gtk.Stack mode_stack;
    private Gtk.Stack position_stack;
    private Gtk.SpinButton digits_spin_button;
    private Gtk.SpinButton start_number_spin_button;
    private Gtk.Entry text_entry;
    private Gtk.Entry letter_sequence_entry;
    private Gtk.Switch upper_case_switch;
    private StringBuilder seq_builder;
    private Gtk.Entry separator_entry;
    private Gtk.Entry search_entry;
    public bool is_first { get; set; }
    public bool is_last { get; set; }

    public signal void remove_request ();
    public signal void move_up_request ();
    public signal void move_down_request ();
    public signal void update_request ();

    construct {
        margin_top = 3;
        margin_bottom = 3;
        hexpand = true;

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL,
            column_spacing = 12
        };

        mode_combo = new Gtk.ComboBoxText () {
            valign = Gtk.Align.CENTER
        };
        mode_combo.insert (RenameMode.TEXT, "TEXT", RenameMode.TEXT.to_string ());
        mode_combo.insert (RenameMode.NUMBER, "NUMBER", RenameMode.NUMBER.to_string ());
        mode_combo.insert (RenameMode.LETTER, "LETTER", RenameMode.LETTER.to_string ());
        mode_combo.insert (RenameMode.DATETIME, "DATETIME", RenameMode.DATETIME.to_string ());

        text_entry = new Gtk.Entry () {
            vexpand = false,
            hexpand = false,
            max_length = 64,
            max_width_chars = 64
        };

        var start_number_label = new Gtk.Label (_("Start Number"));
        start_number_spin_button = new Gtk.SpinButton.with_range (0, int.MAX, 1) {
            digits = 0
        };
        start_number_spin_button.set_value (0.0);

        var digits_label = new Gtk.Label (_("Digits"));

        digits_spin_button = new Gtk.SpinButton.with_range (0, 5, 1) {
            digits = 0
        };

        digits_spin_button.set_value (1.0);

        var digits_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL,
            column_spacing = 6
        };

        digits_grid.add (start_number_label);
        digits_grid.add (start_number_spin_button);
        digits_grid.add (digits_label);
        digits_grid.add (digits_spin_button);

        seq_builder = new StringBuilder ();

        letter_sequence_entry = new Gtk.Entry () {
            placeholder_text = _("Start of sequence"),
            text = "a",
            input_purpose = Gtk.InputPurpose.ALPHA,
            tooltip_text = _("Enter start of alphabetic sequence, 'A' to 'zzzz…'")
        };

        upper_case_switch = new Gtk.Switch () {
            active = false,
            vexpand = false,
            valign = Gtk.Align.CENTER
        };

        var upper_case_label = new Gtk.Label (_("Uppercase"));

        var letters_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL,
            column_spacing = 6
        };

        letters_grid.add (letter_sequence_entry);
        letters_grid.add (upper_case_label);
        letters_grid.add (upper_case_switch);

        date_format_combo = new Gtk.ComboBoxText () {
            valign = Gtk.Align.CENTER
        };
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

        date_picker = new Granite.Widgets.DatePicker ();
        time_picker = new Granite.Widgets.TimePicker ();

        var date_time_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL,
            column_spacing = 6
        };
        date_time_grid.add (date_format_combo);
        date_time_grid.add (date_picker);
        date_time_grid.add (time_picker);

        mode_stack = new Gtk.Stack () {
            valign = Gtk.Align.CENTER,
            homogeneous =false,
            vexpand = false,
            hexpand = false
        };

        mode_stack.add_named (text_entry, "TEXT");
        mode_stack.add_named (digits_grid, "NUMBER");
        mode_stack.add_named (letters_grid, "LETTER");
        mode_stack.add_named (date_time_grid, "DATETIME");
        mode_stack.set_visible_child_name ("TEXT");

        separator_entry = new Gtk.Entry () {
            halign = Gtk.Align.END,
            hexpand = true,
            max_length = 16,
            placeholder_text = _("Separator"),
            text = ""
        };

        var separator_label = new Gtk.Label (_("Separator:")) {
            halign = Gtk.Align.END,
            hexpand = false
        };

        var separator_grid = new Gtk.Grid () {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_start = 12,
            orientation = Gtk.Orientation.HORIZONTAL,
            column_spacing = 6
        };
        separator_grid.add (separator_label);
        separator_grid.add (separator_entry);

        search_entry = new Gtk.Entry () {
            hexpand = true,
            halign = Gtk.Align.END,
            max_length = 64,
            max_width_chars = 64,
            placeholder_text = _("Target text to be replaced")
        };

        position_stack = new Gtk.Stack () {
            hexpand = true,
            valign = Gtk.Align.END
        };
        position_stack.add_named (separator_grid, "SEPARATOR");
        position_stack.add_named (search_entry, "TARGET");

        position_combo = new Gtk.ComboBoxText ();
        position_combo.insert (RenamePosition.SUFFIX, "SUFFIX", RenamePosition.SUFFIX.to_string ());
        position_combo.insert (RenamePosition.PREFIX, "PREFIX", RenamePosition.PREFIX.to_string ());
        position_combo.insert (RenamePosition.REPLACE, "REPLACE", RenamePosition.REPLACE.to_string ());
        position_combo.active = RenamePosition.SUFFIX;

        var move_up_button = new Gtk.Button.from_icon_name ("go-up", Gtk.IconSize.SMALL_TOOLBAR) {
            halign = Gtk.Align.END,
            valign = Gtk.Align.CENTER,
            tooltip_text = (_("Move modification up"))
        };

        move_up_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var move_down_button = new Gtk.Button.from_icon_name ("go-down", Gtk.IconSize.SMALL_TOOLBAR) {
            halign = Gtk.Align.END,
            valign = Gtk.Align.CENTER,
            vexpand = false,
            hexpand = false,
            tooltip_text = (_("Move modification down"))
        };

        move_down_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var move_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL
        };

        move_grid.add (move_up_button);
        move_grid.add (move_down_button);

        var remove_button = new Gtk.Button.from_icon_name ("process-stop", Gtk.IconSize.SMALL_TOOLBAR) {
            halign = Gtk.Align.END,
            valign = Gtk.Align.CENTER,
            tooltip_text = (_("Remove this modification"))
        };
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        grid.add (position_combo);
        grid.add (mode_combo);
        grid.add (mode_stack);
        grid.add (position_stack);
        grid.add (move_grid);
        grid.add (remove_button);

        add (grid);

        show_all ();

        mode_combo.changed.connect (change_rename_mode);
        position_combo.changed.connect (change_rename_position);

        date_format_combo.changed.connect (() => {
            update_request ();
        });

        date_picker.date_changed.connect (() => {
            update_request ();
        });

        time_picker.time_changed.connect (() => {
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

        text_entry.changed.connect (() => {
            update_request ();
        });

        letter_sequence_entry.changed.connect (() => {
            update_request ();
        });

        upper_case_switch.state_set.connect (() => {
            update_request ();
        });

        separator_entry.changed.connect (() => {
            update_request ();
        });

        text_entry.placeholder_text = ((RenamePosition)(position_combo.get_active ())).to_placeholder ();
        position_combo.changed.connect (() => {
            text_entry.placeholder_text = ((RenamePosition)(position_combo.get_active ())).to_placeholder ();
            update_request ();
        });

        remove_button.clicked.connect (() => {
            remove_request ();
        });

        move_up_button.clicked.connect (() => {
            move_up_request ();
        });

        move_down_button.clicked.connect (() => {
            move_down_request ();
        });

        bind_property ("is-first", move_up_button, "sensitive", BindingFlags.INVERT_BOOLEAN | BindingFlags.SYNC_CREATE);
        bind_property ("is-last", move_down_button, "sensitive", BindingFlags.INVERT_BOOLEAN | BindingFlags.SYNC_CREATE);

        reset ();
    }

    public void reset () {
        text_entry.text = "";
        separator_entry.text = "";
        search_entry.text = "";

        letter_sequence_entry.text = "a";
        upper_case_switch.active = false;

        start_number_spin_button.@value = 0;
        digits_spin_button.@value = 1;

        position_combo.active = 0;
        mode_combo.active = 0;
        date_format_combo.active = 0;
    }

    public void change_rename_mode () {
        switch (mode_combo.get_active ()) {
            case RenameMode.TEXT:
                mode_stack.set_visible_child_name ("TEXT");
                break;

            case RenameMode.NUMBER:
                mode_stack.set_visible_child_name ("NUMBER");
                break;

            case RenameMode.LETTER:
                mode_stack.set_visible_child_name ("LETTER");
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

    private string current_letter_seq;
    public string rename (string input, int index) {
        var seq = index + (int)(start_number_spin_button.get_value ());
        if (index == 0) {
            if (upper_case_switch.active) {
               current_letter_seq = letter_sequence_entry.text.up ();
            } else {
               current_letter_seq = letter_sequence_entry.text.down ();
            }

            var pos = letter_sequence_entry.get_position ();
            current_letter_seq = sanitise_letter_sequence (current_letter_seq);
            letter_sequence_entry.text = current_letter_seq;
            letter_sequence_entry.set_position (pos);
        }
        string new_text = "";

        switch (mode_combo.get_active ()) {
            case RenameMode.TEXT:
                new_text = text_entry.text;
                break;

            case RenameMode.NUMBER:
                var template = "%%0%id".printf ((int)(digits_spin_button.get_value ()));
                new_text = template.printf (seq);
                break;

            case RenameMode.LETTER:
                new_text = current_letter_seq;
                current_letter_seq = increment_letter_seq (current_letter_seq);
                break;

            case RenameMode.DATETIME:
                new_text = get_formated_date_time (date_picker.date);
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
                if (search_entry.text != "") {
                    return input.replace (search_entry.text, new_text);
                } else {
                    break;
                }

            default:
                break;
        }

        return input;
    }

    private string increment_letter_seq (string letter_seq) {
        // Before this called, letter_seq must be sanitised to be 'A' - 'zzzzz…'
        seq_builder.assign (letter_seq);
        bool carry = false;
        char start = upper_case_switch.active ? 'A' : 'a';
        char end = upper_case_switch.active ? 'Z' : 'z';
        for (int i = seq_builder.data.length - 1; i >= 0; i--) {
            if (seq_builder.data[i] == end) {
                seq_builder.data[i] = start;
                carry = true;
            } else {
                seq_builder.data[i]++;
                carry = false;
                break;
            }
        }

        if (carry) {
            seq_builder.prepend_c (start);
        }

        return seq_builder.str;
    }

    private string sanitise_letter_sequence (string seq) {
        seq_builder.assign (seq);
        char start = upper_case_switch.active ? 'A' : 'a';
        char end = upper_case_switch.active ? 'Z' : 'z';
        for (int i = seq_builder.data.length - 1; i >= 0; i--) {
            if (seq_builder.data[i] > end) {
                seq_builder.data[i] = end;
            } else if (seq_builder.data[i] < start) {
                seq_builder.data[i] = start;
            }
        }

        return seq_builder.str;
    }

    public string get_formated_date_time (DateTime? date) {
        var time = time_picker.time;
        var date_time = new DateTime.utc (
            date.get_year (), date.get_month (), date.get_day_of_month (),
            time.get_hour (), time.get_minute (), time.get_second ()
        );

        switch (date_format_combo.get_active ()) {
            case RenameDateFormat.DEFAULT_DATE:
                return date_time.format (Granite.DateTime.get_default_date_format (false, true, true));

            case RenameDateFormat.DEFAULT_DATETIME:
                return date_time.format (Granite.DateTime.get_default_date_format (false, true, true).
                                  concat (" ", Granite.DateTime.get_default_time_format ()));

            case RenameDateFormat.LOCALE:
                return date_time.format ("%c");

            case RenameDateFormat.ISO_DATE:
                return date_time.format ("%Y-%m-%d");

            case RenameDateFormat.ISO_DATETIME:
                return date_time.format ("%Y-%m-%d %H:%M:%S");

            default:
                assert_not_reached ();
        }
    }

    public bool is_suffix () {
        return position_combo.active == RenamePosition.SUFFIX;
    }

    public Variant to_variant () {
        VariantBuilder vb = new VariantBuilder (new VariantType ("((is)is(ii)sb(ix)s)"));

        //Suffix/Prefix/Replace (string) combo - enum - type "(is)"
        vb.open (new VariantType ("(is)"));
        vb.add ("i", position_combo.active);
        vb.add ("s", position_combo.active == RenamePosition.REPLACE ? search_entry.text : "");
        vb.close ();

        //Text/Number Sequence/Date combo - enum - type "i"
        vb.add ("i", mode_combo.active);

        //Textsource - string - type "s"
        vb.add ("s", mode_combo.active == RenameMode.TEXT ? text_entry.text : "");

        //NumberSequence start/digits uint/uint - type "(ii)"
        vb.open (new VariantType ("(ii)"));
        if (mode_combo.active == RenameMode.NUMBER) {
            vb.add ("i", (int)(start_number_spin_button.@value));
            vb.add ("i", (int)(digits_spin_button.@value));
        } else {
            vb.add ("i", 0);
            vb.add ("i", 0);
        }

        vb.close ();

        //LetterSequencesource - string - type "s"
        vb.add ("s", mode_combo.active == RenameMode.LETTER ? letter_sequence_entry.text : "");
        vb.add ("b", upper_case_switch.active);

        //DateSequence format/startdatetime enum/int64 - "(ix)"
        vb.open (new VariantType ("(ix)"));
        if (mode_combo.active == RenameMode.DATETIME) {
            vb.add ("i", date_format_combo.active);
            DateTime date = date_picker.date;
            DateTime time = time_picker.time;
            DateTime start_datetime = new DateTime (
                new TimeZone.local (),
                date.get_year (),
                date.get_month (),
                date.get_day_of_month (),
                time.get_hour (),
                time.get_minute (),
                time.get_seconds ()
            );

            vb.add ("x", start_datetime.to_unix ());

        } else {
            vb.add ("i", 0);
            vb.add ("x", 0);
        }

        vb.close ();

        //Separator string - type "s"
        vb.add ("s", separator_entry.text);

        return vb.end ();
    }

    public void set_from_variant (Variant settings) {
        var iter = new VariantIter (settings);
        //Suffix/Prefix/Replace (string) combo - enum - type "(is)"
        int active;
        string text;
        bool upper_case;
        iter.next ("(is)", out active, out text);
        position_combo.active = active.clamp (0, 2);
        search_entry.text = text;

        //Text/Number Sequence/Date combo - enum - type "i"
        iter.next ("i", out active);
        mode_combo.active = active.clamp (0, 2);

        //Textsource - string - type "s"
        iter.next ("s", out text);
        text_entry.text = text;

        //NumberSequence start/digits uint/uint - type "(ii)"
        int start, digits;
        iter.next ("(ii)", out start, out digits);
        start_number_spin_button.@value = (double)(start.clamp (0, int.MAX));
        digits_spin_button.@value = (double)(digits.clamp (0, 5));

        //LetterSequencesource - string - type "s"
        iter.next ("s", out text);
        letter_sequence_entry.text = text;

        //Uppercase - boolean - type "b"
        iter.next ("b", out upper_case);
        upper_case_switch.active = upper_case;

        //DateSequence format/startdatetime enum/int64 - "(ix)"
        int64 start_unix;
        iter.next ("(ix)", out active, out start_unix);
        date_format_combo.active = active.clamp (0, 4);
        DateTime start_datetime = new DateTime.from_unix_local (start_unix.clamp (0, int64.MAX));
        date_picker.date = start_datetime;
        time_picker.time = start_datetime;

        //Separator string - type "s"
        iter.next ("s", out text);
        separator_entry.text = text;
    }
}
