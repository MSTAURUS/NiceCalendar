/* Pure utility functions (SPEC v1.4 §6.5). */

namespace NiceCalendar {

public string autoconstrast_text_color (int r, int g, int b) {
    double y = 0.299 * r + 0.587 * g + 0.114 * b;
    return y > 128 ? "#000000" : "#ffffff";
}

public bool parse_hex_color (string? value, out int r, out int g, out int b) {
    r = g = b = 0;
    if (value == null)
        return false;
    string s = value.strip ();
    if (s.has_prefix ("#"))
        s = s.substring (1);
    if (s.length == 3)
        s = "%c%c%c%c%c%c".printf (s[0], s[0], s[1], s[1], s[2], s[2]);
    if (s.length != 6)
        return false;
    r = (int) ulong.parse (s.substring (0, 2), 16);
    g = (int) ulong.parse (s.substring (2, 2), 16);
    b = (int) ulong.parse (s.substring (4, 2), 16);
    return true;
}

public const string[] DATE_PRESETS = {
    "%d.%m.%Y",
    "%d/%m/%Y",
    "%Y-%m-%d",
    "%d %b",
    "%A, %d %B"
};

public const string[] TIME_PRESETS = {
    "%H:%M",
    "%H:%M:%S",
    "%I:%M %p",
    "%I:%M:%S %p"
};

public string apply_date_preset (string preset, bool show_weekday) {
    if (show_weekday && !preset.has_prefix ("%A, "))
        return "%A, " + preset;
    return preset;
}

public string apply_time_preset (string preset, bool show_seconds, bool use_12h) {
    string result = preset;
    if (use_12h)
        result = result.replace ("%H", "%I");

    bool has_seconds = result.contains ("%S");
    if (show_seconds && !has_seconds) {
        if (result.contains (" %p"))
            result = result.replace (" %p", ":%S %p");
        else
            result = result + ":%S";
    } else if (!show_seconds && has_seconds) {
        result = result.replace (":%S", "");
    }

    if (use_12h && !result.contains ("%p"))
        result = result + " %p";

    return result;
}

public class PanelFormatOpts {
    public bool show_date = true;
    public bool show_time = true;
    public string order = "date-time";
    public string separator = " ";
    public string date_format = "%d.%m.%Y";
    public string time_format = "%H:%M";
    public bool date_format_custom = false;
    public bool time_format_custom = false;
    public bool show_seconds = false;
    public bool use_12h = false;
    public bool show_weekday = false;
}

public string format_panel_text (DateTime now, PanelFormatOpts opts) {
    string[] parts = {};

    if (opts.show_date) {
        string fmt = opts.date_format ?? "%d.%m.%Y";
        if (!opts.date_format_custom)
            fmt = apply_date_preset (fmt, opts.show_weekday);
        string? s = now.format (fmt);
        parts += (s != null && s != "") ? s : now.format ("%d.%m.%Y");
    }

    if (opts.show_time) {
        string fmt = opts.time_format ?? "%H:%M";
        if (!opts.time_format_custom)
            fmt = apply_time_preset (fmt, opts.show_seconds, opts.use_12h);
        string? s = now.format (fmt);
        parts += (s != null && s != "") ? s : now.format ("%H:%M");
    }

    if (parts.length == 0)
        return "";

    if (opts.order == "time-date") {
        string tmp = parts[0];
        if (parts.length > 1) {
            parts[0] = parts[1];
            parts[1] = tmp;
        }
    }

    return string.joinv (opts.separator, parts);
}

public string tooltip_text (DateTime now) {
    return now.format ("%A, %d %B %Y, %H:%M:%S");
}

}
