/* Panel widget (SPEC v1.4 §3). */

namespace NiceCalendar {

public class PanelWidget : Object {
    public Gtk.EventBox event_box { get; private set; }
    public Gtk.Box box { get; private set; }
    public Gtk.Label date_label { get; private set; }
    public Gtk.Label time_label { get; private set; }

    private Config config;
    private uint timer_id = 0;
    private Gtk.Orientation orientation = Gtk.Orientation.HORIZONTAL;
    private bool orientation_known = false;
    private const double VERTICAL_ANGLE = 270.0;
    private Gtk.CssProvider? font_css_date = null;
    private Gtk.CssProvider? font_css_time = null;

    public PanelWidget (Gtk.Builder builder, Config config) {
        this.config = config;
        event_box = builder.get_object ("panel_event_box") as Gtk.EventBox;
        box = builder.get_object ("panel_box") as Gtk.Box;
        date_label = builder.get_object ("date_label") as Gtk.Label;
        time_label = builder.get_object ("time_label") as Gtk.Label;

        event_box.visible_window = true;
        event_box.above_child = true;
        event_box.can_focus = true;
        event_box.app_paintable = true;
        event_box.halign = Gtk.Align.FILL;
        event_box.valign = Gtk.Align.FILL;

        box.halign = Gtk.Align.CENTER;
        box.valign = Gtk.Align.CENTER;
        box.hexpand = true;
        box.vexpand = true;

        foreach (var lbl in new Gtk.Label[] { date_label, time_label }) {
            lbl.halign = Gtk.Align.CENTER;
            lbl.valign = Gtk.Align.CENTER;
            lbl.xalign = 0.5f;
            lbl.yalign = 0.5f;
        }

        event_box.size_allocate.connect (on_size_allocate);
        apply_fonts ();
        refresh ();
        schedule ();
    }

    public Gtk.Widget widget { get { return event_box; } }

    public void set_orientation (Gtk.Orientation orient) {
        if (orient == orientation && orientation_known)
            return;
        orientation = orient;
        orientation_known = true;
        apply_orientation ();
    }

    private void on_size_allocate (Gtk.Allocation alloc) {
        var orient = (alloc.width >= alloc.height)
            ? Gtk.Orientation.HORIZONTAL
            : Gtk.Orientation.VERTICAL;
        set_orientation (orient);
    }

    private void apply_orientation () {
        if (!orientation_known)
            return;
        bool two_line = config.get_bool ("two-line");
        bool show_date = config.get_bool ("show-date");
        bool show_time = config.get_bool ("show-time");

        if (two_line && show_date && show_time) {
            box.orientation = Gtk.Orientation.VERTICAL;
            box.spacing = 0;
            date_label.angle = 0;
            time_label.angle = 0;
        } else {
            box.orientation = orientation;
            box.spacing = 4;
            double angle = (orientation == Gtk.Orientation.VERTICAL) ? VERTICAL_ANGLE : 0;
            date_label.angle = angle;
            time_label.angle = angle;
        }
        refresh ();
    }

    public void apply_fonts () {
        apply_label_font (date_label, config.get_string ("font-date"), ref font_css_date);
        apply_label_font (time_label, config.get_string ("font-time"), ref font_css_time);
    }

    private static void apply_label_font (Gtk.Label lbl, string? font, ref Gtk.CssProvider? prev) {
        var ctx = lbl.get_style_context ();
        if (prev != null)
            ctx.remove_provider (prev);
        prev = null;
        if (font == null || font == "")
            return;
        var provider = new Gtk.CssProvider ();
        string css = "* { font: %s; }".printf (font);
        try {
            provider.load_from_data (css);
            ctx.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            prev = provider;
        } catch (Error e) {
            warning ("font css: %s", e.message);
        }
    }

    public void refresh () {
        var now = new DateTime.now_local ();
        var opts = config.panel_opts ();
        string text = format_panel_text (now, opts);

        bool show_date = opts.show_date;
        bool show_time = opts.show_time;
        string order = opts.order;
        bool two_line = config.get_bool ("two-line");

        date_label.visible = show_date;
        time_label.visible = show_time;

        if (show_date && show_time) {
            string date_part = "";
            string time_part = "";
            /* re-split for separate labels */
            var o2 = new PanelFormatOpts ();
            o2.show_date = true; o2.show_time = false;
            o2.date_format = opts.date_format;
            o2.date_format_custom = opts.date_format_custom;
            o2.show_weekday = opts.show_weekday;
            date_part = format_panel_text (now, o2);

            o2.show_date = false; o2.show_time = true;
            o2.time_format = opts.time_format;
            o2.time_format_custom = opts.time_format_custom;
            o2.show_seconds = opts.show_seconds;
            o2.use_12h = opts.use_12h;
            time_part = format_panel_text (now, o2);

            date_label.label = date_part;
            time_label.label = time_part;

            if (order == "time-date") {
                box.reorder_child (time_label, 0);
                box.reorder_child (date_label, 1);
            } else {
                box.reorder_child (date_label, 0);
                box.reorder_child (time_label, 1);
            }
        } else if (show_date) {
            date_label.label = text;
        } else if (show_time) {
            time_label.label = text;
        }

        if (two_line && show_date && show_time) {
            box.orientation = Gtk.Orientation.VERTICAL;
            box.spacing = 0;
        } else if (orientation_known) {
            box.orientation = orientation;
            box.spacing = 4;
        }

        if (config.get_bool ("show-tooltip"))
            event_box.tooltip_text = tooltip_text (now);
        else
            event_box.tooltip_text = null;
    }

    public void schedule () {
        if (timer_id != 0) {
            Source.remove (timer_id);
            timer_id = 0;
        }
        if (config.get_bool ("show-seconds"))
            timer_id = Timeout.add (200, align_to_second);
        else
            timer_id = Timeout.add (500, align_to_minute);
        refresh ();
    }

    private bool align_to_second () {
        var now = new DateTime.now_local ();
        if (now.get_microsecond () < 50000) {
            timer_id = Timeout.add (1000, on_tick);
            return false;
        }
        refresh ();
        return true;
    }

    private bool align_to_minute () {
        var now = new DateTime.now_local ();
        if (now.get_second () == 0 && now.get_microsecond () < 500000) {
            timer_id = Timeout.add_seconds (60, on_tick);
            return false;
        }
        refresh ();
        return true;
    }

    private bool on_tick () {
        refresh ();
        return true;
    }

    public void dispose_timer () {
        if (timer_id != 0) {
            Source.remove (timer_id);
            timer_id = 0;
        }
    }
}

}
