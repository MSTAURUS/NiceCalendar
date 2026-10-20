/* Settings dialog (SPEC v1.4 §5). */

namespace NiceCalendar {

public class SettingsDialog : Object {
    public Gtk.Dialog dialog { get; private set; }
    private Config config;
    private bool loading = false;

    private Gtk.CheckButton chk_show_date;
    private Gtk.CheckButton chk_show_time;
    private Gtk.ComboBoxText cmb_order;
    private Gtk.Entry ent_separator;
    private Gtk.ComboBoxText cmb_date_format;
    private Gtk.Entry ent_date_format;
    private Gtk.ComboBoxText cmb_time_format;
    private Gtk.Entry ent_time_format;
    private Gtk.CheckButton chk_seconds;
    private Gtk.CheckButton chk_12h;
    private Gtk.CheckButton chk_weekday;
    private Gtk.CheckButton chk_two_line;

    private Gtk.FontButton fnt_date;
    private Gtk.FontButton fnt_time;
    private Gtk.FontButton fnt_calendar;
    private Gtk.FontButton fnt_popup_time;

    private Gtk.ComboBoxText cmb_first_day;
    private Gtk.ComboBoxText cmb_background;
    private Gtk.ColorButton col_background;
    private Gtk.ComboBoxText cmb_today_color;
    private Gtk.ColorButton col_today;
    private Gtk.ComboBoxText cmb_selection_color;
    private Gtk.ColorButton col_selection;
    private Gtk.CheckButton chk_adjacent;
    private Gtk.CheckButton chk_tooltip;

    public signal void applied ();

    public SettingsDialog (Gtk.Builder builder, Config config) {
        this.config = config;
        dialog = builder.get_object ("settings_dialog") as Gtk.Dialog;
        dialog.hide ();

        chk_show_date = builder.get_object ("chk_show_date") as Gtk.CheckButton;
        chk_show_time = builder.get_object ("chk_show_time") as Gtk.CheckButton;
        cmb_order = builder.get_object ("cmb_order") as Gtk.ComboBoxText;
        ent_separator = builder.get_object ("ent_separator") as Gtk.Entry;
        cmb_date_format = builder.get_object ("cmb_date_format") as Gtk.ComboBoxText;
        ent_date_format = builder.get_object ("ent_date_format") as Gtk.Entry;
        cmb_time_format = builder.get_object ("cmb_time_format") as Gtk.ComboBoxText;
        ent_time_format = builder.get_object ("ent_time_format") as Gtk.Entry;
        chk_seconds = builder.get_object ("chk_seconds") as Gtk.CheckButton;
        chk_12h = builder.get_object ("chk_12h") as Gtk.CheckButton;
        chk_weekday = builder.get_object ("chk_weekday") as Gtk.CheckButton;
        chk_two_line = builder.get_object ("chk_two_line") as Gtk.CheckButton;

        fnt_date = builder.get_object ("fnt_date") as Gtk.FontButton;
        fnt_time = builder.get_object ("fnt_time") as Gtk.FontButton;
        fnt_calendar = builder.get_object ("fnt_calendar") as Gtk.FontButton;
        fnt_popup_time = builder.get_object ("fnt_popup_time") as Gtk.FontButton;

        cmb_first_day = builder.get_object ("cmb_first_day") as Gtk.ComboBoxText;
        cmb_background = builder.get_object ("cmb_background") as Gtk.ComboBoxText;
        col_background = builder.get_object ("col_background") as Gtk.ColorButton;
        cmb_today_color = builder.get_object ("cmb_today_color") as Gtk.ComboBoxText;
        col_today = builder.get_object ("col_today") as Gtk.ColorButton;
        cmb_selection_color = builder.get_object ("cmb_selection_color") as Gtk.ComboBoxText;
        col_selection = builder.get_object ("col_selection") as Gtk.ColorButton;
        chk_adjacent = builder.get_object ("chk_adjacent") as Gtk.CheckButton;
        chk_tooltip = builder.get_object ("chk_tooltip") as Gtk.CheckButton;

        var btn_reset = builder.get_object ("btn_reset") as Gtk.Button;
        var btn_close = builder.get_object ("btn_close") as Gtk.Button;

        load_values ();
        connect_signals ();
        if (btn_reset != null)
            btn_reset.clicked.connect (on_reset);
        if (btn_close != null)
            btn_close.clicked.connect (() => dialog.hide ());
        dialog.delete_event.connect (() => { dialog.hide (); return true; });
    }

    public void present () {
        load_values ();
        dialog.present ();
    }

    private void load_values () {
        loading = true;
        var c = config;
        chk_show_date.active = c.get_bool ("show-date");
        chk_show_time.active = c.get_bool ("show-time");
        set_combo_id (cmb_order, c.get_string ("order"));
        ent_separator.text = c.get_string ("separator");

        bool dcustom = c.get_bool ("date-format-custom");
        if (dcustom) {
            set_combo_id (cmb_date_format, "__custom__");
            ent_date_format.text = c.get_string ("date-format");
            ent_date_format.sensitive = true;
        } else {
            set_combo_id (cmb_date_format, c.get_string ("date-format"));
            ent_date_format.sensitive = false;
        }

        bool tcustom = c.get_bool ("time-format-custom");
        if (tcustom) {
            set_combo_id (cmb_time_format, "__custom__");
            ent_time_format.text = c.get_string ("time-format");
            ent_time_format.sensitive = true;
        } else {
            set_combo_id (cmb_time_format, c.get_string ("time-format"));
            ent_time_format.sensitive = false;
        }

        chk_seconds.active = c.get_bool ("show-seconds");
        chk_12h.active = c.get_bool ("use-12h");
        chk_weekday.active = c.get_bool ("show-weekday");
        if (chk_two_line != null)
            chk_two_line.active = c.get_bool ("two-line");

        set_font (fnt_date, c.get_string ("font-date"));
        set_font (fnt_time, c.get_string ("font-time"));
        set_font (fnt_calendar, c.get_string ("font-calendar"));
        set_font (fnt_popup_time, c.get_string ("font-popup-time"));

        set_combo_id (cmb_first_day, c.get_string ("first-day-of-week"));
        set_combo_id (cmb_background, c.get_string ("background"));
        set_color (col_background, c.get_string ("background-color"));
        set_combo_id (cmb_today_color, c.get_string ("today-color"));
        set_color (col_today, c.get_string ("today-color-custom"));
        set_combo_id (cmb_selection_color, c.get_string ("selection-color"));
        set_color (col_selection, c.get_string ("selection-color-custom"));
        chk_adjacent.active = c.get_bool ("show-adjacent-days");
        chk_tooltip.active = c.get_bool ("show-tooltip");

        update_sensitivities ();
        loading = false;
    }

    private void connect_signals () {
        chk_show_date.toggled.connect (() => apply_bool ("show-date", chk_show_date.active));
        chk_show_time.toggled.connect (() => apply_bool ("show-time", chk_show_time.active));
        cmb_order.changed.connect (() => apply_string ("order", cmb_order.active_id));
        ent_separator.changed.connect (() => apply_string ("separator", ent_separator.text));

        cmb_date_format.changed.connect (() => {
            if (loading) return;
            string id = cmb_date_format.active_id;
            if (id == "__custom__") {
                config.set_bool ("date-format-custom", true);
                ent_date_format.sensitive = true;
            } else {
                config.set_bool ("date-format-custom", false);
                config.set_string ("date-format", id);
                ent_date_format.sensitive = false;
            }
            update_sensitivities ();
            applied ();
        });
        ent_date_format.changed.connect (() => {
            if (loading) return;
            config.set_string ("date-format", ent_date_format.text);
            applied ();
        });

        cmb_time_format.changed.connect (() => {
            if (loading) return;
            string id = cmb_time_format.active_id;
            if (id == "__custom__") {
                config.set_bool ("time-format-custom", true);
                ent_time_format.sensitive = true;
            } else {
                config.set_bool ("time-format-custom", false);
                config.set_string ("time-format", id);
                ent_time_format.sensitive = false;
            }
            update_sensitivities ();
            applied ();
        });
        ent_time_format.changed.connect (() => {
            if (loading) return;
            config.set_string ("time-format", ent_time_format.text);
            applied ();
        });

        chk_seconds.toggled.connect (() => apply_bool ("show-seconds", chk_seconds.active));
        chk_12h.toggled.connect (() => apply_bool ("use-12h", chk_12h.active));
        chk_weekday.toggled.connect (() => apply_bool ("show-weekday", chk_weekday.active));
        if (chk_two_line != null)
            chk_two_line.toggled.connect (() => apply_bool ("two-line", chk_two_line.active));

        fnt_date.font_set.connect (() => apply_font ("font-date", fnt_date));
        fnt_time.font_set.connect (() => apply_font ("font-time", fnt_time));
        fnt_calendar.font_set.connect (() => apply_font ("font-calendar", fnt_calendar));
        fnt_popup_time.font_set.connect (() => apply_font ("font-popup-time", fnt_popup_time));

        cmb_first_day.changed.connect (() => apply_string ("first-day-of-week", cmb_first_day.active_id));
        cmb_background.changed.connect (() => {
            apply_string ("background", cmb_background.active_id);
            update_sensitivities ();
        });
        col_background.color_set.connect (() => apply_color ("background-color", col_background));
        cmb_today_color.changed.connect (() => {
            apply_string ("today-color", cmb_today_color.active_id);
            update_sensitivities ();
        });
        col_today.color_set.connect (() => apply_color ("today-color-custom", col_today));
        cmb_selection_color.changed.connect (() => {
            apply_string ("selection-color", cmb_selection_color.active_id);
            update_sensitivities ();
        });
        col_selection.color_set.connect (() => apply_color ("selection-color-custom", col_selection));
        chk_adjacent.toggled.connect (() => apply_bool ("show-adjacent-days", chk_adjacent.active));
        chk_tooltip.toggled.connect (() => apply_bool ("show-tooltip", chk_tooltip.active));
    }

    private void apply_bool (string key, bool v) {
        if (loading) return;
        config.set_bool (key, v);
        update_sensitivities ();
        applied ();
    }

    private void apply_string (string key, string? v) {
        if (loading || v == null) return;
        config.set_string (key, v);
        applied ();
    }

    private void apply_font (string key, Gtk.FontButton btn) {
        if (loading) return;
        config.set_string (key, btn.font ?? "");
        applied ();
    }

    private void apply_color (string key, Gtk.ColorButton btn) {
        if (loading) return;
        var rgba = btn.rgba;
        string hex = "#%02x%02x%02x".printf (
            (int) (rgba.red * 255), (int) (rgba.green * 255), (int) (rgba.blue * 255));
        config.set_string (key, hex);
        applied ();
    }

    private void on_reset () {
        config.reset ();
        load_values ();
        applied ();
    }

    private void update_sensitivities () {
        bool custom_date = cmb_date_format.active_id == "__custom__";
        bool custom_time = cmb_time_format.active_id == "__custom__";
        chk_seconds.sensitive = !custom_time;
        chk_12h.sensitive = !custom_time;
        chk_weekday.sensitive = !custom_date;
        if (col_background != null)
            col_background.sensitive = cmb_background.active_id == "custom";
        if (col_today != null)
            col_today.sensitive = cmb_today_color.active_id == "custom";
        if (col_selection != null)
            col_selection.sensitive = cmb_selection_color.active_id == "custom";
    }

    private static void set_combo_id (Gtk.ComboBoxText cmb, string id) {
        if (cmb == null) return;
        cmb.active_id = id;
    }

    private static void set_font (Gtk.FontButton btn, string font) {
        if (btn == null) return;
        if (font != null && font != "")
            btn.font = font;
    }

    private static void set_color (Gtk.ColorButton btn, string hex) {
        if (btn == null) return;
        var rgba = Gdk.RGBA ();
        if (rgba.parse (hex))
            btn.rgba = rgba;
    }
}

}
