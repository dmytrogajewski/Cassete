#!/usr/bin/env bash

set -euo pipefail

if [ -z "${PROJECT_DIR:-}" ]; then
  if [ -f "/workspace/meson.build" ]; then
    PROJECT_DIR="/workspace"
  else
    PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
  fi
fi

cd "$PROJECT_DIR"

BUILD_DIR=${BUILD_DIR:-build-release}
DIST_DIR="$PROJECT_DIR/$BUILD_DIR/package"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

if [ -z "${APP_VERSION:-}" ]; then
  echo "APP_VERSION environment variable must be set to build packages." >&2
  exit 1
fi
VERSION="$APP_VERSION"

# Prepare staging area
DESTDIR="$DIST_DIR/stage"
rm -rf "$DESTDIR"
mkdir -p "$DESTDIR"

meson install -C "$PROJECT_DIR/$BUILD_DIR" --destdir "$DESTDIR"

# Build Debian package
fpm -s dir -t deb \
  -C "$DESTDIR" \
  -p "$DIST_DIR/cassette_${VERSION}_amd64.deb" \
  --name cassette \
  --version "$VERSION" \
  --architecture amd64 \
  --description "Cassette - Unofficial Yandex Music client for GNOME" \
  --url "https://github.com/dmytrogajewski/Cassete" \
  --license "GPL-3.0-or-later" \
  usr

# Build RPM package
fpm -s dir -t rpm \
  -C "$DESTDIR" \
  -p "$DIST_DIR/cassette_${VERSION}_x86_64.rpm" \
  --name cassette \
  --version "$VERSION" \
  --architecture x86_64 \
  --description "Cassette - Unofficial Yandex Music client for GNOME" \
  --url "https://github.com/dmytrogajewski/Cassete" \
  --license "GPL-3.0-or-later" \
  usr

rm -rf "$DESTDIR"

echo "Packages created in $DIST_DIR:"
ls -1 "$DIST_DIR"

