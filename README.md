# NiceCalendar (Vala)

XFCE 4.18 panel plugin — clock with Windows 10-style calendar popup.

Port of the Python NiceCalendar (SPEC v1.4) to native Vala / internal plugin.

## Build

```bash
meson setup build
meson compile -C build
sudo meson install -C build
```

Dependencies: `libxfce4panel-2.0`, `libxfconf-0`, `gtk+-3.0`, Vala, Meson.

## Structure

- `src/calendar_grid.vala`, `utils.vala` — pure logic (no GTK)
- `src/config.vala` — xfconf
- `src/theme.vala`, `panel_widget.vala`, `popup.vala`, `settings_dialog.vala`, `plugin.vala` — GTK
- `ui/*.ui` — GtkBuilder

## Install paths

- Module: `$libdir/xfce4/panel/plugins/libnicecalendar.so`
- Desktop: `$datadir/xfce4/panel/plugins/nicecalendar.desktop`
- UI: `$datadir/nicecalendar/ui/`
- Icon: `$datadir/icons/hicolor/scalable/apps/nicecalendar.svg`
