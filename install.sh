#!/usr/bin/env bash
# NiceCalendar (Vala) install
# Internal XFCE plugins: .so + .desktop must be in system panel paths.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Need: $1" >&2; exit 1; }
}

need meson
need ninja
need pkg-config
pkg-config --exists libxfce4panel-2.0 || { echo "Need: libxfce4panel-2.0-dev" >&2; exit 1; }
pkg-config --exists libxfconf-0 || { echo "Need: libxfconf-0-dev" >&2; exit 1; }
command -v valac >/dev/null 2>&1 || { echo "Need: valac" >&2; exit 1; }

PANEL_LIBDIR="$(pkg-config --variable=libdir libxfce4panel-2.0)"
MODULE_DIR="${PANEL_LIBDIR}/xfce4/panel/plugins"
SYS_DESKTOP_DIR="/usr/share/xfce4/panel/plugins"
USER_PREFIX="${HOME}/.local"

echo "Panel module dir: ${MODULE_DIR}"

BUILD="${ROOT}/build"
rm -rf "${BUILD}"

meson setup "${BUILD}" \
  --prefix="${USER_PREFIX}" \
  --libdir=lib \
  -Dbuildtype=release

meson compile -C "${BUILD}"
meson install -C "${BUILD}"

SO="$(find "${BUILD}" -name 'libnicecalendar.so' | head -1)"
if [ -z "${SO}" ]; then
  echo "libnicecalendar.so not found in build" >&2
  exit 1
fi

install_as_root() {
  local src="$1" dst="$2" mode="$3"
  if [ -w "$(dirname "$dst")" ]; then
    install -m "${mode}" "${src}" "${dst}"
  else
    echo "Need root for: ${dst}"
    sudo install -m "${mode}" "${src}" "${dst}"
  fi
}

install_as_root "${SO}" "${MODULE_DIR}/libnicecalendar.so" 755
echo "Module  → ${MODULE_DIR}/libnicecalendar.so"

# User desktop (optional)
mkdir -p "${USER_PREFIX}/share/xfce4/panel/plugins"
install -m 644 "${ROOT}/data/nicecalendar.desktop" \
  "${USER_PREFIX}/share/xfce4/panel/plugins/nicecalendar.desktop"

# System desktop — required for the item to appear in the add dialog
install_as_root "${ROOT}/data/nicecalendar.desktop" \
  "${SYS_DESKTOP_DIR}/nicecalendar.desktop" 644
echo "Desktop → ${SYS_DESKTOP_DIR}/nicecalendar.desktop"

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "${USER_PREFIX}/share/icons/hicolor" 2>/dev/null || true
fi


# System locales (gettext often looks here first for panel process)
if command -v msgfmt >/dev/null 2>&1 && [ -f "${ROOT}/po/LINGUAS" ]; then
  while read -r lang; do
    [ -z "${lang}" ] && continue
    po="${ROOT}/po/${lang}.po"
    [ -f "${po}" ] || continue
    tmpmo="$(mktemp)"
    msgfmt -o "${tmpmo}" "${po}" 2>/dev/null || continue
    for dest in \
      "${USER_PREFIX}/share/locale/${lang}/LC_MESSAGES" \
      "/usr/share/locale/${lang}/LC_MESSAGES"
    do
      if [ -w "$(dirname "$dest")" ] 2>/dev/null || [ -w "$dest" ] 2>/dev/null; then
        mkdir -p "$dest"
        install -m 644 "${tmpmo}" "${dest}/nicecalendar.mo"
      else
        sudo mkdir -p "$dest"
        sudo install -m 644 "${tmpmo}" "${dest}/nicecalendar.mo"
      fi
    done
    rm -f "${tmpmo}"
    echo "  locale: ${lang}"
  done < "${ROOT}/po/LINGUAS"
fi


echo ""
echo "OK. Restart panel:"
echo "  xfce4-panel --quit; sleep 1; xfce4-panel &"
