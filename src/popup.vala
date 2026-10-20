/* Calendar popover (SPEC v1.4 §4, §6.6, §6.7). */

namespace NiceCalendar {

public class Popup : Object {
    public Gtk.Window window { get; private set; }
    private Gtk.Popover? popover; /* unused when using Window fallback */
    private Gtk.Box box;
    private Gtk.Label big_time;
    private Gtk.Label date_sub;
    private Gtk.Label header_label;
    private Gtk.Button prev_btn;
    private Gtk.Button next_btn;
    private Gtk.Grid grid;

    private Config config;
    private Gtk.Widget parent_widget;

    private DateTime? selected = null;
    private DateTime focus_month;
    private DateTime? focused_date = null;
    private Gtk.Button[] day_buttons = {};
    private DateTime[] day_dates = {};
    private uint minute_timer = 0;
    private DateTime last_day;
    private Gtk.CssProvider? css_provider = null;
    private Gtk.CssProvider? font_css_big = null;
    private Gtk.CssProvider? font_css_header = null;

    public Popup (Gtk.Builder builder, Config config, Gtk.Widget parent) {
        this.config = config;
        this.parent_widget = parent;
        this.focus_month = new DateTime.now_local ();
        this.last_day = new DateTime.now_local ();
        this.focused_date = new DateTime.now_local ();

        popover = builder.get_object ("popup") as Gtk.Popover;
        box = builder.get_object ("popup_box") as Gtk.Box;
        big_time = builder.get_object ("popup_big_time") as Gtk.Label;
        date_sub = builder.get_object ("popup_date_sub") as Gtk.Label;
        header_label = builder.get_object ("popup_header_label") as Gtk.Label;
        prev_btn = builder.get_object ("popup_prev_btn") as Gtk.Button;
        next_btn = builder.get_object ("popup_next_btn") as Gtk.Button;
        grid = builder.get_object ("popup_grid") as Gtk.Grid;

        big_time.get_style_context ().add_class ("nicecalendar-big-time");

        /* Gtk.Popover unreliable inside Gtk.Plug → undecorated Window */
        window = new Gtk.Window (Gtk.WindowType.TOPLEVEL);
        window.decorated = false;
        window.skip_taskbar_hint = true;
        window.skip_pager_hint = true;
        window.resizable = false;
        window.type_hint = Gdk.WindowTypeHint.NORMAL;
        window.set_keep_above (true);
        window.accept_focus = true;
        window.focus_on_map = true;
        window.can_focus = true;

        if (box.get_parent () != null)
            box.unparent ();
        window.add (box);

        prev_btn.clicked.connect (() => shift (-1));
        next_btn.clicked.connect (() => shift (1));
        prev_btn.set_tooltip_text (_("Previous month"));
        next_btn.set_tooltip_text (_("Next month"));
        window.set_title (_("Calendar"));
        window.get_accessible ().set_name (_("Calendar"));
        prev_btn.get_accessible ().set_name (_("Previous month"));
        next_btn.get_accessible ().set_name (_("Next month"));

        window.key_press_event.connect (on_key);
        window.add_events (Gdk.EventMask.SCROLL_MASK | Gdk.EventMask.SMOOTH_SCROLL_MASK);
        window.scroll_event.connect (on_scroll);
        window.focus_out_event.connect (() => {
            /* close on focus loss (click outside) after short delay */
            Timeout.add (100, () => {
                if (!window.has_toplevel_focus)
                    popdown ();
                return false;
            });
            return false;
        });

        apply_css ();
        rebuild ();
    }

    public void popup () {
        if (window.visible) {
            popdown ();
            return;
        }
        focused_date = new DateTime.now_local ();
        focus_month = focused_date;
        selected = null;
        rebuild ();
        update_header_time ();
        position_window ();
        window.show_all ();
        window.present ();
        schedule_minute ();
    }

    public void popdown () {
        window.hide ();
        cancel_minute ();
        selected = null;
    }

    public bool is_visible () {
        return window.visible;
    }

    private void position_window () {
        var gdk_win = parent_widget.get_window ();
        if (gdk_win == null) {
            parent_widget.realize ();
            gdk_win = parent_widget.get_window ();
        }
        if (gdk_win == null)
            return;

        int ox, oy;
        gdk_win.get_origin (out ox, out oy);

        int wx = 0, wy = 0;
        var toplevel = parent_widget.get_toplevel ();
        if (toplevel != null && toplevel is Gtk.Widget)
            parent_widget.translate_coordinates ((Gtk.Widget) toplevel, 0, 0, out wx, out wy);

        Gtk.Allocation alloc;
        parent_widget.get_allocation (out alloc);

        window.realize ();
        window.queue_resize ();
        int ww, wh;
        window.get_size (out ww, out wh);
        if (ww < 2 || wh < 2) {
            Gtk.Requisition min, nat;
            window.get_preferred_size (out min, out nat);
            ww = int.max (nat.width, 320);
            wh = int.max (nat.height, 280);
        }

        int x = ox + wx;
        /* prefer above the panel widget */
        int y = oy + wy - wh - 2;
        if (y < 8)
            y = oy + wy + alloc.height + 2;

        var display = gdk_win.get_display ();
        var monitor = display.get_monitor_at_window (gdk_win);
        if (monitor != null) {
            var geo = monitor.get_geometry ();
            x = int.max (geo.x, int.min (x, geo.x + geo.width - ww));
            y = int.max (geo.y, int.min (y, geo.y + geo.height - wh));
        }

        window.move (x, y);
    }


    private static void apply_widget_font (Gtk.Widget w, string? font, ref Gtk.CssProvider? prev) {
        var ctx = w.get_style_context ();
        if (prev != null)
            ctx.remove_provider (prev);
        prev = null;
        if (font == null || font == "")
            return;
        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data ("* { font: %s; }".printf (font));
            ctx.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            prev = provider;
        } catch (Error e) {
            warning ("font css: %s", e.message);
        }
    }

    public void apply_css () {
        css_provider = apply_popup_css (window, config, css_provider);
        apply_widget_font (big_time, config.get_string ("font-popup-time"), ref font_css_big);
        apply_widget_font (header_label, config.get_string ("font-calendar"), ref font_css_header);
    }

    private void update_header_time () {
        var now = new DateTime.now_local ();
        string fmt = config.get_bool ("show-seconds") ? "%H:%M:%S" : "%H:%M";
        big_time.label = now.format (fmt);
        date_sub.label = now.format ("%A, %d %B %Y");
    }

    private int first_weekday () {
        return resolve_first_weekday (config.get_string ("first-day-of-week"));
    }

    private void rebuild () {
        /* clear grid children beyond structure */
        var children = grid.get_children ();
        foreach (var c in children) {
            if (c is Gtk.Button)
                grid.remove (c);
        }
        day_buttons = {};
        day_dates = {};

        int year = focus_month.get_year ();
        int month = focus_month.get_month ();
        int fwd = first_weekday ();
        var cells = month_grid (year, month, fwd);
        bool show_adj = config.get_bool ("show-adjacent-days");

        /* weekday headers */
        var order = weekday_order (fwd);
        for (int col = 0; col < 7; col++) {
            /* find existing label or create */
            var existing = grid.get_child_at (col, 0);
            Gtk.Label lbl;
            if (existing is Gtk.Label) {
                lbl = existing as Gtk.Label;
            } else {
                lbl = new Gtk.Label (null);
                lbl.get_style_context ().add_class ("nicecalendar-weekday-header");
                grid.attach (lbl, col, 0, 1, 1);
            }
            /* Monday=0 → format via a known date */
            var sample = new DateTime.local (2024, 1, 1 + order[col], 0, 0, 0); /* Jan 1 2024 = Mon */
            if (sample != null)
                lbl.label = sample.format ("%a");
            else
                lbl.label = "";
        }

        var today = new DateTime.now_local ();
        DateTime? focus_target = focused_date;

        for (int i = 0; i < GRID_CELLS; i++) {
            var d = cells[i];
            int row = 1 + i / 7;
            int col = i % 7;
            bool in_month = is_same_month (d, year, month);
            if (!show_adj && !in_month)
                continue;

            var btn = new Gtk.Button.with_label ("%d".printf (d.get_day_of_month ()));
            btn.relief = Gtk.ReliefStyle.NONE;
            btn.can_focus = true;
            var ctx = btn.get_style_context ();
            ctx.add_class ("nicecalendar-day");
            if (!in_month)
                ctx.add_class ("nicecalendar-adjacent");
            if (is_same_day (d, today))
                ctx.add_class ("nicecalendar-today");
            if (selected != null && is_same_day (d, selected) && in_month
                && !is_same_day (d, today))
                ctx.add_class ("nicecalendar-selected");

            btn.set_tooltip_text (d.format ("%d %B %Y, %A"));
            btn.get_accessible ().set_name (d.format ("%d %B %Y, %A"));
            DateTime captured = d;
            btn.clicked.connect (() => on_day_clicked (captured));
            btn.add_events (Gdk.EventMask.SCROLL_MASK | Gdk.EventMask.SMOOTH_SCROLL_MASK);
            btn.scroll_event.connect (on_scroll);

            grid.attach (btn, col, row, 1, 1);
            day_buttons += btn;
            day_dates += d;
        }

        header_label.label = focus_month.format ("%B %Y");
        grid.show_all ();

        if (focus_target != null)
            focus_day (focus_target);
        else
            focus_day (today);
    }

    private void on_day_clicked (DateTime d) {
        int year = focus_month.get_year ();
        int month = focus_month.get_month ();
        if (!is_same_month (d, year, month)) {
            focus_month = d;
            focused_date = d;
            rebuild ();
            return;
        }
        if (selected != null && is_same_day (d, selected))
            selected = null;
        else if (!is_same_day (d, new DateTime.now_local ()))
            selected = d;
        focused_date = d;
        rebuild ();
    }

    private void shift (int delta) {
        int y, m;
        shift_month (focus_month.get_year (), focus_month.get_month (), delta, out y, out m);
        focus_month = new DateTime.local (y, m, 1, 0, 0, 0);
        if (focus_month == null)
            focus_month = new DateTime.now_local ();
        if (focused_date != null) {
            int max_day = 28;
            for (int d = 29; d <= 31; d++) {
                var t2 = new DateTime.local (y, m, d, 0, 0, 0);
                if (t2 == null || t2.get_month () != m)
                    break;
                max_day = d;
            }
            int day = int.min (focused_date.get_day_of_month (), max_day);
            focused_date = new DateTime.local (y, m, day, 0, 0, 0);
            if (focused_date == null)
                focused_date = new DateTime.local (y, m, 1, 0, 0, 0);
        }
        if (focus_month == null)
            focus_month = new DateTime.local (y, m, 1, 0, 0, 0);
        rebuild ();
    }

    private bool focus_day (DateTime target) {
        for (int i = 0; i < day_dates.length; i++) {
            if (is_same_day (day_dates[i], target)) {
                day_buttons[i].grab_focus ();
                focused_date = target;
                return true;
            }
        }
        return false;
    }

    private bool on_scroll (Gdk.EventScroll ev) {
        if (ev.direction == Gdk.ScrollDirection.UP) {
            shift (-1);
            return true;
        }
        if (ev.direction == Gdk.ScrollDirection.DOWN) {
            shift (1);
            return true;
        }
        if (ev.direction == Gdk.ScrollDirection.SMOOTH) {
            double dx, dy;
            ev.get_scroll_deltas (out dx, out dy);
            if (dy < -0.1) {
                shift (-1);
                return true;
            }
            if (dy > 0.1) {
                shift (1);
                return true;
            }
        }
        return false;
    }

    private void move_by_days (int delta) {
        var cur = focused_date ?? new DateTime.now_local ();
        var target = cur.add_days (delta);
        focused_date = target;
        if (!is_same_month (target, focus_month.get_year (), focus_month.get_month ())) {
            focus_month = target;
            rebuild ();
            return;
        }
        if (!focus_day (target))
            rebuild ();
    }

    private bool on_key (Gdk.EventKey ev) {
        uint key = ev.keyval;
        if (key == Gdk.Key.Escape) {
            popdown ();
            return true;
        }
        if (key == Gdk.Key.Page_Up || key == Gdk.Key.KP_Page_Up) {
            shift (-1);
            return true;
        }
        if (key == Gdk.Key.Page_Down || key == Gdk.Key.KP_Page_Down) {
            shift (1);
            return true;
        }
        if (key == Gdk.Key.Home || key == Gdk.Key.KP_Home) {
            var today = new DateTime.now_local ();
            focus_month = today;
            focused_date = today;
            rebuild ();
            return true;
        }
        if (key == Gdk.Key.Left || key == Gdk.Key.KP_Left) {
            move_by_days (-1);
            return true;
        }
        if (key == Gdk.Key.Right || key == Gdk.Key.KP_Right) {
            move_by_days (1);
            return true;
        }
        if (key == Gdk.Key.Up || key == Gdk.Key.KP_Up) {
            move_by_days (-7);
            return true;
        }
        if (key == Gdk.Key.Down || key == Gdk.Key.KP_Down) {
            move_by_days (7);
            return true;
        }
        if (key == Gdk.Key.Return || key == Gdk.Key.KP_Enter
            || key == Gdk.Key.space || key == Gdk.Key.KP_Space) {
            if (focused_date != null)
                on_day_clicked (focused_date);
            return true;
        }
        return false;
    }

    private void schedule_minute () {
        cancel_minute ();
        minute_timer = Timeout.add_seconds (60, on_minute);
    }

    private void cancel_minute () {
        if (minute_timer != 0) {
            Source.remove (minute_timer);
            minute_timer = 0;
        }
    }

    private bool on_minute () {
        if (!window.visible) {
            minute_timer = 0;
            return false;
        }
        update_header_time ();
        var today = new DateTime.now_local ();
        if (!is_same_day (today, last_day)) {
            last_day = today;
            rebuild ();
        }
        return true;
    }
}

}
