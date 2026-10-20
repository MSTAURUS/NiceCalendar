/* Theme / CSS helpers (SPEC v1.4 §4.7, §6.6). Full port of Python theme.py. */

namespace NiceCalendar {

private const string FALLBACK_ACCENT = "#3584e4";
private const string DARK_BG = "#2b2b2b";
private const string DARK_FG = "#f0f0f0";
private const string LIGHT_BG = "#ffffff";
private const string LIGHT_FG = "#1a1a1a";

private bool? _panel_is_dark_cache = null;

private Gdk.RGBA? probe_css_color (string css_value) {
    try {
        var provider = new Gtk.CssProvider ();
        provider.load_from_data ("label { color: %s; }".printf (css_value));
        var probe = new Gtk.Label (null);
        var ctx = probe.get_style_context ();
        ctx.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        return ctx.get_color (Gtk.StateFlags.NORMAL);
    } catch (Error e) {
        return null;
    }
}

private void rgba_to_rgb (Gdk.RGBA rgba, out int r, out int g, out int b) {
    r = (int) Math.round (rgba.red * 255);
    g = (int) Math.round (rgba.green * 255);
    b = (int) Math.round (rgba.blue * 255);
}

public void theme_accent_rgb (out int r, out int g, out int b) {
    var rgba = probe_css_color ("@theme_selected_bg_color");
    if (rgba != null) {
        rgba_to_rgb (rgba, out r, out g, out b);
        if (!(r == 0 && g == 0 && b == 0))
            return;
    }
    if (!parse_hex_color (FALLBACK_ACCENT, out r, out g, out b)) {
        r = 53; g = 132; b = 228;
    }
}

private string hex (int r, int g, int b) {
    return "#%02x%02x%02x".printf (r, g, b);
}

private string resolve_accent (string spec, string custom_hex, int ar, int ag, int ab) {
    if (spec == "custom") {
        int r, g, b;
        if (parse_hex_color (custom_hex, out r, out g, out b))
            return hex (r, g, b);
    }
    return hex (ar, ag, ab);
}

private void probe_panel_style_colors (out int? bg_r, out int? bg_g, out int? bg_b,
                                       out int? fg_r, out int? fg_g, out int? fg_b) {
    bg_r = bg_g = bg_b = null;
    fg_r = fg_g = fg_b = null;
    Gtk.Window? win = null;
    try {
        win = new Gtk.Window (Gtk.WindowType.TOPLEVEL);
        win.decorated = false;
        win.set_default_size (1, 1);
        win.opacity = 0;
        var w = new Gtk.EventBox ();
        w.name = "nicecalendar-panel-probe";
        win.add (w);
        var ctx = w.get_style_context ();
        foreach (var cls in new string[] { "xfce4-panel", "background", "panel", "panel-background" })
            ctx.add_class (cls);
        win.show_all ();

        var rgba = ctx.get_color (Gtk.StateFlags.NORMAL);
        int r, g, b;
        rgba_to_rgb (rgba, out r, out g, out b);
        fg_r = r; fg_g = g; fg_b = b;

        /* get_background_color is deprecated; use theme CSS variable */
        {
            var alt = probe_css_color ("@theme_bg_color");
            if (alt != null) {
                int ar, ag, ab;
                rgba_to_rgb (alt, out ar, out ag, out ab);
                bg_r = ar; bg_g = ag; bg_b = ab;
            }
        }
        if (fg_r == null || (fg_r == 0 && fg_g == 0 && fg_b == 0)) {
            var alt = probe_css_color ("@theme_fg_color");
            if (alt != null) {
                int ar, ag, ab;
                rgba_to_rgb (alt, out ar, out ag, out ab);
                fg_r = ar; fg_g = ag; fg_b = ab;
            }
        }
    } finally {
        if (win != null)
            win.destroy ();
    }
}

public bool panel_is_dark () {
    if (_panel_is_dark_cache != null)
        return _panel_is_dark_cache;

    int? br, bg, bb, fr, fg, fb;
    probe_panel_style_colors (out br, out bg, out bb, out fr, out fg, out fb);

    if (br != null) {
        double y = 0.299 * br + 0.587 * bg + 0.114 * bb;
        _panel_is_dark_cache = y < 128;
        return _panel_is_dark_cache;
    }
    if (fr != null) {
        double y = 0.299 * fr + 0.587 * fg + 0.114 * fb;
        _panel_is_dark_cache = y > 128;
        return _panel_is_dark_cache;
    }
    _panel_is_dark_cache = false;
    return false;
}

public void panel_colors (out int? bg_r, out int? bg_g, out int? bg_b,
                          out int fg_r, out int fg_g, out int fg_b) {
    int? br, bg, bb, fr, fg, fb;
    probe_panel_style_colors (out br, out bg, out bb, out fr, out fg, out fb);
    bg_r = br; bg_g = bg; bg_b = bb;

    if (fr != null && !(fr == 0 && fg == 0 && fb == 0)) {
        fg_r = fr; fg_g = fg; fg_b = fb;
        return;
    }
    if (panel_is_dark ()) {
        parse_hex_color (DARK_FG, out fg_r, out fg_g, out fg_b);
    } else {
        parse_hex_color (LIGHT_FG, out fg_r, out fg_g, out fg_b);
    }
}

public void invalidate_panel_cache () {
    _panel_is_dark_cache = null;
}

private string panel_label_css () {
    int? br, bg, bb;
    int fr, fg, fb;
    panel_colors (out br, out bg, out bb, out fr, out fg, out fb);
    string fg_hex = hex (fr, fg, fb);
    return """
.nicecalendar-panel,
.nicecalendar-panel > * {
  background-color: transparent;
  background-image: none;
  border: none;
  box-shadow: none;
  opacity: 1.0;
}
.nicecalendar-panel label {
  color: %s;
  background-color: transparent;
  opacity: 1.0;
}
""".printf (fg_hex);
}

public string build_popup_css (Config config) {
    int ar, ag, ab;
    theme_accent_rgb (out ar, out ag, out ab);

    string today = resolve_accent (
        config.get_string ("today-color"),
        config.get_string ("today-color-custom"),
        ar, ag, ab);
    string sel = resolve_accent (
        config.get_string ("selection-color"),
        config.get_string ("selection-color-custom"),
        ar, ag, ab);

    string fg_hex;
    string bg_line;
    string bg_mode = config.get_string ("background");
    if (bg_mode == "custom") {
        string bg = config.get_string ("background-color");
        int r, g, b;
        if (!parse_hex_color (bg, out r, out g, out b)) {
            r = 255; g = 255; b = 255;
            bg = "#ffffff";
        }
        fg_hex = autoconstrast_text_color (r, g, b);
        bg_line = "background-color: %s; color: %s;".printf (bg, fg_hex);
    } else if (bg_mode == "dark") {
        fg_hex = DARK_FG;
        bg_line = "background-color: %s; color: %s;".printf (DARK_BG, DARK_FG);
    } else if (bg_mode == "light") {
        fg_hex = LIGHT_FG;
        bg_line = "background-color: %s; color: %s;".printf (LIGHT_BG, LIGHT_FG);
    } else if (panel_is_dark ()) {
        /* system theme, dark panel */
        fg_hex = DARK_FG;
        bg_line = "background-color: %s; color: %s;".printf (DARK_BG, DARK_FG);
    } else {
        /* system theme, light panel: blend with the panel background */
        fg_hex = LIGHT_FG;
        bg_line = "background-color: @theme_bg_color; color: %s;".printf (fg_hex);
    }

    var sb = new StringBuilder ();
    sb.append (".nicecalendar-popup, window.nicecalendar-popup { padding: 0; %s }\n".printf (bg_line));
    sb.append (".nicecalendar-popup * { color: %s; }\n".printf (fg_hex));
    sb.append (".nicecalendar-big-time { font-weight: bold; color: %s; }\n".printf (fg_hex));
    sb.append (".nicecalendar-weekday-header { opacity: 0.7; font-weight: 500; color: %s; }\n".printf (fg_hex));
    sb.append (".nicecalendar-day { min-width: 28px; min-height: 22px; border-radius: 4px; padding: 2px 6px; border: 1px solid transparent; color: %s; background: transparent; background-image: none; box-shadow: none; }\n".printf (fg_hex));
    sb.append (".nicecalendar-day:hover { background-color: alpha(currentColor, 0.08); }\n");
    sb.append (".nicecalendar-day:focus { border-color: alpha(currentColor, 0.35); }\n");
    sb.append (".nicecalendar-day.nicecalendar-adjacent { opacity: 0.45; color: %s; }\n".printf (fg_hex));
    sb.append (".nicecalendar-day.nicecalendar-today { border: 1px solid %s; border-radius: 4px; color: %s; }\n".printf (today, fg_hex));
    sb.append (".nicecalendar-day.nicecalendar-selected { border: 1px solid %s; border-radius: 0; color: %s; }\n".printf (sel, fg_hex));
    sb.append (".nicecalendar-popup label { color: %s; }\n".printf (fg_hex));
    sb.append (".nicecalendar-popup button { color: %s; }\n".printf (fg_hex));

    return sb.str;
}

public Gtk.CssProvider apply_popup_css (Gtk.Widget widget, Config config, Gtk.CssProvider? prev) {
    var css = build_popup_css (config);
    var provider = new Gtk.CssProvider ();
    try {
        provider.load_from_data (css);
    } catch (Error e) {
        warning ("CSS load: %s", e.message);
    }

    var ctx = widget.get_style_context ();
    ctx.add_class ("nicecalendar-popup");
    if (prev != null)
        ctx.remove_provider (prev);
    ctx.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

    var screen = widget.get_screen ();
    if (prev != null)
        Gtk.StyleContext.remove_provider_for_screen (screen, prev);
    Gtk.StyleContext.add_provider_for_screen (screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

    return provider;
}

public Gtk.CssProvider? apply_panel_css (Gtk.Widget[] widgets, Gtk.CssProvider? prev) {
    invalidate_panel_cache ();
    string css = panel_label_css ();
    var provider = new Gtk.CssProvider ();
    try {
        provider.load_from_data (css);
    } catch (Error e) {
        return prev;
    }

    foreach (var w in widgets) {
        if (w == null)
            continue;
        var ctx = w.get_style_context ();
        ctx.add_class ("nicecalendar-panel");
        if (prev != null)
            ctx.remove_provider (prev);
        ctx.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

        /* color via CSS provider only */
    }

    if (widgets.length > 0 && widgets[0] != null) {
        var screen = widgets[0].get_screen ();
        if (prev != null)
            Gtk.StyleContext.remove_provider_for_screen (screen, prev);
        Gtk.StyleContext.add_provider_for_screen (screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    }

    return provider;
}

public void make_transparent (Gtk.Widget widget) {
    var screen = widget.get_screen ();
    var visual = screen.get_rgba_visual ();
    if (visual != null && screen.is_composited ())
        widget.set_visual (visual);
    widget.app_paintable = true;
}

}
