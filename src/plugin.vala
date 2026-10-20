/* NiceCalendar — internal XFCE panel plugin (Vala port of SPEC v1.4). */

namespace NiceCalendar {


private string find_locale_dir () {
    string[] candidates = {
        Path.build_filename (Environment.get_home_dir (), ".local", "share", "locale"),
        Path.build_filename (Environment.get_user_data_dir (), "locale"),
        LOCALEDIR,
        "/usr/local/share/locale",
        "/usr/share/locale",
    };
    string full = Environment.get_variable ("LANG") ?? "en_US";
    if (full.contains ("."))
        full = full.split (".")[0];
    string lang = full.contains ("_") ? full.split ("_")[0] : full;
    foreach (var locdir in candidates) {
        string mo_full = Path.build_filename (locdir, full, "LC_MESSAGES", "nicecalendar.mo");
        if (FileUtils.test (mo_full, FileTest.EXISTS))
            return locdir;
        string mo = Path.build_filename (locdir, lang, "LC_MESSAGES", "nicecalendar.mo");
        if (FileUtils.test (mo, FileTest.EXISTS))
            return locdir;
    }
    return LOCALEDIR;
}

private string find_ui (string name) {
    string[] candidates = {
        Path.build_filename (Environment.get_current_dir (), "ui", name),
        Path.build_filename (Environment.get_home_dir (), ".local", "share", "nicecalendar", "ui", name),
        Path.build_filename (PKGDATADIR, "ui", name),
        Path.build_filename ("/usr/share/nicecalendar/ui", name),
    };
    foreach (var p in candidates) {
        if (FileUtils.test (p, FileTest.EXISTS))
            return p;
    }
    critical ("UI file not found: %s", name);
    return "";
}

private Gtk.Builder load_builder (string name) {
    var b = new Gtk.Builder ();
    b.set_translation_domain ("nicecalendar");
    try {
        b.add_from_file (find_ui (name));
    } catch (Error e) {
        critical ("Cannot load %s: %s", name, e.message);
        Process.exit (1);
    }
    return b;
}

public class Plugin : Xfce.PanelPlugin {
    private Config config;
    private PanelWidget panel;
    private Popup popup;
    private SettingsDialog settings;
    private Gtk.CssProvider? panel_css = null;

    public override void @construct () {
        string localedir = find_locale_dir ();
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain ("nicecalendar", localedir);
        Intl.bind_textdomain_codeset ("nicecalendar", "UTF-8");
        Intl.textdomain ("nicecalendar");
        Intl.setlocale (LocaleCategory.TIME, "");
        Intl.setlocale (LocaleCategory.MESSAGES, "");

        config = new Config (this.unique_id);

        var panel_builder = load_builder ("panel.ui");
        panel = new PanelWidget (panel_builder, config);
        add (panel.widget);
        add_action_widget (panel.widget);
        panel.widget.show_all ();

        var popup_builder = load_builder ("popup.ui");
        popup = new Popup (popup_builder, config, panel.widget);

        var settings_builder = load_builder ("settings.ui");
        settings = new SettingsDialog (settings_builder, config);

        make_transparent (panel.event_box);
        make_transparent (panel.date_label);
        make_transparent (panel.time_label);
        panel_css = apply_panel_css (
            new Gtk.Widget[] { panel.event_box, panel.date_label, panel.time_label },
            panel_css);

        /* clicks */
        panel.event_box.button_press_event.connect (on_button);

        /* orientation from panel */
        orientation_changed.connect ((o) => panel.set_orientation (o));
        panel.set_orientation (this.orientation);

        size_changed.connect ((size) => {
            panel.refresh ();
            return true;
        });

        menu_show_about ();
        menu_show_configure ();
        about.connect (on_about);
        configure_plugin.connect (() => settings.present ());

        config.changed.connect (on_config_changed);
        settings.applied.connect (on_config_changed);

        /* theme changes */
        var settings_gtk = Gtk.Settings.get_default ();
        if (settings_gtk != null) {
            settings_gtk.notify["gtk-theme-name"].connect (() => {
                invalidate_panel_cache ();
                popup.apply_css ();
                panel_css = apply_panel_css (
                    new Gtk.Widget[] { panel.event_box, panel.date_label, panel.time_label },
                    panel_css);
            });
        }

        destroy.connect (() => {
            panel.dispose_timer ();
            popup.popdown ();
        });
    }

    private bool on_button (Gdk.EventButton ev) {
        if (ev.button == 1) {
            popup.popup ();
            return true;
        }
        if (ev.button == 3) {
            /* let XFCE show the standard menu (Properties / About) */
            return false;
        }
        return false;
    }

    private void on_config_changed () {
        panel.apply_fonts ();
        panel.schedule ();
        panel.refresh ();
        popup.apply_css ();
    }

    private void on_about () {
        var dlg = new Gtk.AboutDialog ();
        dlg.program_name = "NiceCalendar";
        dlg.version = PACKAGE_VERSION;
        dlg.comments = _("Clock with a calendar popup in Windows 10 style");
        dlg.license_type = Gtk.License.GPL_2_0;
        dlg.logo_icon_name = "nicecalendar";
        dlg.transient_for = null;
        dlg.run ();
        dlg.destroy ();
    }
}

}

[CCode (cname = "xfce_panel_module_init")]
public Type xfce_panel_module_init (TypeModule module, out bool make_resident) {
    make_resident = true;
    return typeof (NiceCalendar.Plugin);
}
