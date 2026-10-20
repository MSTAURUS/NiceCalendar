# Optional unit tests (pure logic, no GTK)
test_calendar = executable('test-calendar-grid',
  files('test_calendar_grid.vala', '../src/calendar_grid.vala', '../src/locale_helper.c'),
  dependencies: [glib_dep, gobject_dep],
  vala_args: ['--target-glib=2.50'],
  build_by_default: false,
)
test('calendar_grid', test_calendar, suite: 'unit')

test_utils_exe = executable('test-utils',
  files('test_utils.vala', '../src/utils.vala'),
  dependencies: [glib_dep, gobject_dep],
  vala_args: ['--target-glib=2.50'],
  build_by_default: false,
)
test('utils', test_utils_exe, suite: 'unit')
