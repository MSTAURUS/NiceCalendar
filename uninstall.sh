#!/usr/bin/env bash
set -euo pipefail

PREFIX="${HOME}/.local"
PANEL_LIBDIR="$(pkg-config --variable=libdir libxfce4panel-2.0 2>/dev/null || echo /usr/lib/x86_64-linux-gnu)"
MODULE_DIR="${PANEL_LIBDIR}/xfce4/panel/plugins"

rm -f "${PREFIX}/share/xfce4/panel/plugins/nicecalendar.desktop"
rm -rf "${PREFIX}/share/nicecalendar"
rm -f "${PREFIX}/share/icons/hicolor/scalable/apps/nicecalendar.svg"
find "${PREFIX}/share/locale" -name 'nicecalendar.mo' -delete 2>/dev/null || true
rm -f "${PREFIX}/lib/xfce4/panel/plugins/libnicecalendar.so" 2>/dev/null || true

rm_root() {
  local f="$1"
  [ -e "$f" ] || return 0
  if [ -w "$(dirname "$f")" ]; then
    rm -f "$f"
  else
    sudo rm -f "$f"
  fi
}

rm_root "${MODULE_DIR}/libnicecalendar.so"
rm_root /usr/share/xfce4/panel/plugins/nicecalendar.desktop

echo "Uninstalled. Restart: xfce4-panel --quit; sleep 1; xfce4-panel &"
