/* xfconf wrapper. Must not depend on Gtk. */

namespace NiceCalendar {

public class Config : Object {
    public signal void changed (string key);

    public int plugin_id { get; private set; }

    private Xfconf.Channel? channel;
    private string prefix;
    private HashTable<string, Value?> store;

    public static HashTable<string, Value?> defaults;

    static construct {
        defaults = new HashTable<string, Value?> (str_hash, str_equal);
        defaults["show-date"] = true;
        defaults["show-time"] = true;
        defaults["order"] = "date-time";
        defaults["separator"] = " ";
        defaults["date-format"] = "%d.%m.%Y";
        defaults["time-format"] = "%H:%M";
        defaults["date-format-custom"] = false;
        defaults["time-format-custom"] = false;
        defaults["show-seconds"] = false;
        defaults["use-12h"] = false;
        defaults["show-weekday"] = false;
        defaults["font-date"] = "";
        defaults["font-time"] = "";
        defaults["font-calendar"] = "";
        defaults["font-popup-time"] = "";
        defaults["first-day-of-week"] = "locale";
        defaults["background"] = "theme";
        defaults["background-color"] = "#ffffff";
        defaults["today-color"] = "accent";
        defaults["today-color-custom"] = "#3584e4";
        defaults["selection-color"] = "accent";
        defaults["selection-color-custom"] = "#3584e4";
        defaults["show-adjacent-days"] = true;
        defaults["show-tooltip"] = true;
        defaults["two-line"] = false;
    }

    public Config (int plugin_id) {
        this.plugin_id = plugin_id;
        this.prefix = "/plugins/plugin-%d/".printf (plugin_id);
        this.store = new HashTable<string, Value?> (str_hash, str_equal);

        try {
            Xfconf.init ();
            channel = new Xfconf.Channel ("xfce4-panel");
            channel.property_changed.connect (on_prop_changed);
        } catch (Error e) {
            warning ("Xfconf unavailable: %s — in-memory only", e.message);
            channel = null;
        }
    }

    private void on_prop_changed (string prop, Value val) {
        if (prop.has_prefix (prefix))
            changed (prop.substring (prefix.length));
    }

    public bool get_bool (string key) {
        if (channel != null) {
            string full = prefix + key;
            if (channel.has_property (full))
                return channel.get_bool (full, false);
        } else if (store.contains (key)) {
            var v = store[key];
            if (v != null && v.holds (typeof (bool)))
                return v.get_boolean ();
        }
        var d = defaults[key];
        return d != null && d.holds (typeof (bool)) ? d.get_boolean () : false;
    }

    public string get_string (string key) {
        if (channel != null) {
            string full = prefix + key;
            if (channel.has_property (full))
                return channel.get_string (full, "");
        } else if (store.contains (key)) {
            var v = store[key];
            if (v != null && v.holds (typeof (string)))
                return v.get_string ();
        }
        var d = defaults[key];
        return d != null && d.holds (typeof (string)) ? d.get_string () : "";
    }

    public void set_bool (string key, bool value) {
        if (channel != null) {
            channel.set_bool (prefix + key, value);
        } else {
            store[key] = value;
            changed (key);
        }
    }

    public void set_string (string key, string value) {
        if (channel != null) {
            channel.set_string (prefix + key, value);
        } else {
            store[key] = value;
            changed (key);
        }
    }

    public void reset () {
        if (channel != null) {
            channel.reset_property (prefix, true);
        } else {
            store.remove_all ();
        }
    }

    public PanelFormatOpts panel_opts () {
        var o = new PanelFormatOpts ();
        o.show_date = get_bool ("show-date");
        o.show_time = get_bool ("show-time");
        o.order = get_string ("order");
        o.separator = get_string ("separator");
        o.date_format = get_string ("date-format");
        o.time_format = get_string ("time-format");
        o.date_format_custom = get_bool ("date-format-custom");
        o.time_format_custom = get_bool ("time-format-custom");
        o.show_seconds = get_bool ("show-seconds");
        o.use_12h = get_bool ("use-12h");
        o.show_weekday = get_bool ("show-weekday");
        return o;
    }
}

}
