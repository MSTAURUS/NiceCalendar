/* Calendar grid model — pure logic, no GTK (SPEC v1.4 §6.5). */

namespace NiceCalendar {

public const int WEEKDAY_MONDAY = 0;
public const int WEEKDAY_SATURDAY = 5;
public const int WEEKDAY_SUNDAY = 6;
public const int WEEKDAYS = 7;
public const int GRID_ROWS = 6;
public const int GRID_CELLS = WEEKDAYS * GRID_ROWS; /* 42 */

public int resolve_first_weekday (string? override) {
    if (override == "mon")
        return WEEKDAY_MONDAY;
    if (override == "sun")
        return WEEKDAY_SUNDAY;
    if (override == "sat")
        return WEEKDAY_SATURDAY;
    return locale_first_weekday ();
}

[CCode (cname = "nicecalendar_locale_first_weekday")]
private static extern int nicecalendar_locale_first_weekday ();

private int locale_first_weekday () {
    return nicecalendar_locale_first_weekday ();
}

public DateTime[] month_grid (int year, int month, int first_weekday) {
    var first = new DateTime.local (year, month, 1, 0, 0, 0);
    if (first == null)
        first = new DateTime.now_local ();
    /* DateTime.get_day_of_week (): Monday=1 .. Sunday=7 */
    int wd = first.get_day_of_week () - 1; /* → Monday=0 .. Sunday=6 */
    int offset = (wd - first_weekday + WEEKDAYS) % WEEKDAYS;
    var start = first.add_days (-offset);
    DateTime[] cells = new DateTime[GRID_CELLS];
    for (int i = 0; i < GRID_CELLS; i++) {
        var d = start.add_days (i);
        cells[i] = d ?? start;
    }
    return cells;
}

public int[] weekday_order (int first_weekday) {
    int[] order = new int[WEEKDAYS];
    for (int i = 0; i < WEEKDAYS; i++)
        order[i] = (first_weekday + i) % WEEKDAYS;
    return order;
}

public void header_month (DateTime[] cells, out int year, out int month) {
    var counts = new HashTable<string, int> (str_hash, str_equal);
    foreach (var d in cells) {
        if (d == null)
            continue;
        string key = "%d-%d".printf (d.get_year (), d.get_month ());
        counts[key] = counts.contains (key) ? counts[key] + 1 : 1;
    }
    string best = null;
    int best_n = 0;
    counts.foreach ((k, v) => {
        if (v > best_n) {
            best_n = v;
            best = k;
        }
    });
    if (best != null) {
        var parts = best.split ("-");
        year = int.parse (parts[0]);
        month = int.parse (parts[1]);
    } else if (cells.length > 0 && cells[0] != null) {
        year = cells[0].get_year ();
        month = cells[0].get_month ();
    } else {
        var now = new DateTime.now_local ();
        year = now.get_year ();
        month = now.get_month ();
    }
}

public void shift_month (int year, int month, int delta, out int new_year, out int new_month) {
    int total = year * 12 + (month - 1) + delta;
    new_year = total / 12;
    new_month = (total % 12) + 1;
    if (new_month <= 0) {
        new_month += 12;
        new_year--;
    }
}

public bool is_same_month (DateTime? d, int year, int month) {
    if (d == null)
        return false;
    return d.get_year () == year && d.get_month () == month;
}

public bool is_same_day (DateTime? a, DateTime? b) {
    if (a == null || b == null)
        return false;
    return a.get_year () == b.get_year ()
        && a.get_month () == b.get_month ()
        && a.get_day_of_month () == b.get_day_of_month ();
}

}
