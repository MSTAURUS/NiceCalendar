/* Unit tests for utils — no GTK. */
void test_autoconstrast () {
    assert (NiceCalendar.autoconstrast_text_color (255, 255, 255) == "#000000");
    assert (NiceCalendar.autoconstrast_text_color (0, 0, 0) == "#ffffff");
    assert (NiceCalendar.autoconstrast_text_color (129, 129, 129) == "#000000");
    assert (NiceCalendar.autoconstrast_text_color (128, 128, 128) == "#ffffff");
    assert (NiceCalendar.autoconstrast_text_color (127, 127, 127) == "#ffffff");
    assert (NiceCalendar.autoconstrast_text_color (255, 0, 0) == "#ffffff");
}

void test_hex () {
    int r, g, b;
    assert (NiceCalendar.parse_hex_color ("#ff8000", out r, out g, out b));
    assert (r == 255 && g == 128 && b == 0);
    assert (NiceCalendar.parse_hex_color ("#f80", out r, out g, out b));
    assert (r == 255 && g == 136 && b == 0);
    assert (NiceCalendar.parse_hex_color ("00ff00", out r, out g, out b));
    assert (r == 0 && g == 255 && b == 0);
    assert (!NiceCalendar.parse_hex_color ("zz", out r, out g, out b));
    assert (!NiceCalendar.parse_hex_color (null, out r, out g, out b));
}

void test_presets () {
    assert (NiceCalendar.apply_time_preset ("%H:%M", true, false) == "%H:%M:%S");
    assert (NiceCalendar.apply_time_preset ("%H:%M", false, true) == "%I:%M %p");
    assert (NiceCalendar.apply_time_preset ("%H:%M", true, true) == "%I:%M:%S %p");
    assert (NiceCalendar.apply_date_preset ("%d.%m.%Y", true) == "%A, %d.%m.%Y");
    assert (NiceCalendar.apply_date_preset ("%A, %d.%m.%Y", true) == "%A, %d.%m.%Y");
}

void test_format_panel () {
    var d = new DateTime.local (2026, 9, 16, 14, 5, 0);
    var opts = new NiceCalendar.PanelFormatOpts ();
    opts.show_date = true;
    opts.show_time = true;
    opts.date_format = "%Y-%m-%d";
    opts.time_format = "%H:%M";
    opts.date_format_custom = true;
    opts.time_format_custom = true;
    opts.separator = " ";
    opts.order = "date-time";
    assert (NiceCalendar.format_panel_text (d, opts) == "2026-09-16 14:05");

    opts.show_date = false;
    assert (NiceCalendar.format_panel_text (d, opts) == "14:05");
}

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/utils/autoconstrast", test_autoconstrast);
    Test.add_func ("/utils/hex", test_hex);
    Test.add_func ("/utils/presets", test_presets);
    Test.add_func ("/utils/format", test_format_panel);
    return Test.run ();
}
