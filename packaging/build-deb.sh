#!/usr/bin/env bash
# Build a binary .deb package for NiceCalendar.
#
#   ./packaging/build-deb.sh [output-dir]
#
# Requires: meson, ninja, valac, pkg-config, dpkg-dev (dpkg-deb)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PKG_NAME="nicecalendar"
BUILD_DIR="${ROOT}/build-deb"
STAGE_DIR="${BUILD_DIR}/stage"
DIST_DIR="${1:-${ROOT}/dist}"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Need: $1" >&2; exit 1; }
}

need meson
need ninja
need valac
need pkg-config
need dpkg-deb
need msgfmt

for dep in gtk+-3.0 libxfce4panel-2.0 libxfce4util-1.0 libxfconf-0; do
  pkg-config --exists "$dep" || { echo "Need pkg-config: $dep" >&2; exit 1; }
done

VERSION="$(awk -F"'" '/^[[:space:]]*version:/ {print $2; exit}' meson.build)"
[ -n "$VERSION" ] || { echo "Cannot parse version from meson.build" >&2; exit 1; }

ARCH="$(dpkg --print-architecture)"
if command -v dpkg-architecture >/dev/null 2>&1; then
  MULTIARCH="$(dpkg-architecture -qDEB_HOST_MULTIARCH)"
else
  MULTIARCH="$(gcc -print-multiarch)"
fi

echo "Package : ${PKG_NAME} ${VERSION} (${ARCH})"

rm -rf "$BUILD_DIR" "$STAGE_DIR"
mkdir -p "$DIST_DIR"

meson setup "$BUILD_DIR" \
  --prefix=/usr \
  --libdir="lib/${MULTIARCH}" \
  --buildtype=release

meson compile -C "$BUILD_DIR"

DESTDIR="$STAGE_DIR" meson install -C "$BUILD_DIR"

# Debian control file
mkdir -p "${STAGE_DIR}/DEBIAN"
sed -e "s|@PKG_NAME@|${PKG_NAME}|g" \
    -e "s|@VERSION@|${VERSION}|g" \
    -e "s|@ARCH@|${ARCH}|g" \
    "${ROOT}/packaging/debian/control.in" > "${STAGE_DIR}/DEBIAN/control"

# md5sums for file integrity
(
  cd "$STAGE_DIR"
  find . -path ./DEBIAN -prune -o -type f -print \
    | sed 's|^\./||' \
    | sort \
    | xargs -r md5sum > DEBIAN/md5sums
)

DEB="${DIST_DIR}/${PKG_NAME}_${VERSION}_${ARCH}.deb"
rm -f "$DEB"
dpkg-deb --root-owner-group --build "$STAGE_DIR" "$DEB"

echo ""
echo "OK: $DEB"
dpkg-deb --info "$DEB" | sed 's/^/    /'
