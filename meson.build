project('nicecalendar', 'vala', 'c',
  version: '1.4.0',
  meson_version: '>= 0.56.0',
  default_options: ['warning_level=1', 'buildtype=debugoptimized']
)

vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

gnome = import('gnome')
i18n = import('i18n')

gtk_dep = dependency('gtk+-3.0', version: '>= 3.24')
xfce_panel_dep = dependency('libxfce4panel-2.0')
xfce_util_dep = dependency('libxfce4util-1.0')
xfconf_dep = dependency('libxfconf-0')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('PACKAGE_VERSION', meson.project_version())
conf.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
conf.set_quoted('PKGDATADIR', join_paths(get_option('prefix'), get_option('datadir'), meson.project_name()))

config_h = configure_file(
  output: 'config.h',
  configuration: conf
)

vapi_dir = meson.current_source_dir() / 'vapi'

sources = files(
  'src/calendar_grid.vala',
  'src/utils.vala',
  'src/config.vala',
  'src/config_constants.vala',
  'src/theme.vala',
  'src/panel_widget.vala',
  'src/popup.vala',
  'src/settings_dialog.vala',
  'src/plugin.vala',
  'src/locale_helper.c',
)

shared_module('nicecalendar',
  sources,
  dependencies: [gtk_dep, xfce_panel_dep, xfce_util_dep, xfconf_dep, glib_dep, gobject_dep],
  vala_args: [
    '--pkg=gtk+-3.0',
    '--pkg=libxfce4panel-2.0',
    '--pkg=libxfce4util-1.0',
    '--pkg=libxfconf-0',
    '--target-glib=2.50',
      ],
  c_args: ['-DGETTEXT_PACKAGE="nicecalendar"'],
  install: true,
  install_dir: join_paths(get_option('libdir'), 'xfce4', 'panel', 'plugins')
)

install_data('data/nicecalendar.desktop',
  install_dir: join_paths(get_option('datadir'), 'xfce4', 'panel', 'plugins')
)

install_data('data/icons/nicecalendar.svg',
  install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
)

install_data([
  'ui/panel.ui',
  'ui/popup.ui',
  'ui/settings.ui',
], install_dir: join_paths(get_option('datadir'), meson.project_name(), 'ui'))

subdir('po')

# subdir('tests')  # enable: meson test
