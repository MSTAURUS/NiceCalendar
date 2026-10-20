/* Unit tests for calendar_grid — no GTK. */
void test_first_weekday_overrides () {
    assert (NiceCalendar.resolve_first_weekday ("mon") == 0);
    assert (NiceCalendar.resolve_first_weekday ("sun") == 6);
    assert (NiceCalendar.resolve_first_weekday ("sat") == 5);
}

void test_month_grid_42 () {
    var cells = NiceCalendar.month_grid (2026, 9, 0);
    assert (cells.length == 42);
}

void test_monday_start () {
    var cells = NiceCalendar.month_grid (2026, 9, 0);
    assert (cells[0].get_year () == 2026);
    assert (cells[0].get_month () == 8);
    assert (cells[0].get_day_of_month () == 31);
}

void test_sunday_start () {
    var cells = NiceCalendar.month_grid (2026, 9, 6);
    assert (cells[0].get_day_of_month () == 30);
    assert (cells[0].get_month () == 8);
}

void test_weekday_order () {
    var o = NiceCalendar.weekday_order (0);
    assert (o[0] == 0 && o[6] == 6);
    o = NiceCalendar.weekday_order (6);
    assert (o[0] == 6 && o[1] == 0);
}

void test_header_month () {
    var cells = NiceCalendar.month_grid (2026, 9, 0);
    int y, m;
    NiceCalendar.header_month (cells, out y, out m);
    assert (y == 2026 && m == 9);
}

void test_shift_month () {
    int y, m;
    NiceCalendar.shift_month (2026, 12, 1, out y, out m);
    assert (y == 2027 && m == 1);
    NiceCalendar.shift_month (2026, 1, -1, out y, out m);
    assert (y == 2025 && m == 12);
    NiceCalendar.shift_month (2026, 6, 12, out y, out m);
    assert (y == 2027 && m == 6);
}

void test_same_day_month () {
    var a = new DateTime.local (2026, 9, 16, 0, 0, 0);
    var b = new DateTime.local (2026, 9, 16, 12, 0, 0);
    var c = new DateTime.local (2026, 9, 17, 0, 0, 0);
    assert (NiceCalendar.is_same_day (a, b));
    assert (!NiceCalendar.is_same_day (a, c));
    assert (NiceCalendar.is_same_month (a, 2026, 9));
    assert (!NiceCalendar.is_same_month (a, 2026, 8));
}

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/calendar/first_weekday", test_first_weekday_overrides);
    Test.add_func ("/calendar/grid_42", test_month_grid_42);
    Test.add_func ("/calendar/monday_start", test_monday_start);
    Test.add_func ("/calendar/sunday_start", test_sunday_start);
    Test.add_func ("/calendar/weekday_order", test_weekday_order);
    Test.add_func ("/calendar/header", test_header_month);
    Test.add_func ("/calendar/shift", test_shift_month);
    Test.add_func ("/calendar/same", test_same_day_month);
    return Test.run ();
}
