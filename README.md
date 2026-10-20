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

## Debian package

```bash
./packaging/build-deb.sh          # -> dist/nicecalendar_<version>_amd64.deb
```

The version is taken from `meson.build`. Package metadata lives in
`packaging/debian/control.in`.

## CI

`.github/workflows/build-deb.yml` builds the `.deb` on every push to `master`
(artifact in the run summary) and attaches it to a GitHub Release when a
`v*` tag is pushed.

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

<center><img width="345" height="363" alt="изображение" src="https://github.com/user-attachments/assets/6587f520-06f9-49f7-a4a3-a43a4f964f4a"/></center>
