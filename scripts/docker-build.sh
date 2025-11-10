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

BUILD_DIR=${BUILD_DIR:-build}
BUILD_TYPE=${BUILD_TYPE:-debugoptimized}
PREFIX=${PREFIX:-/usr}
RUN_TESTS=${RUN_TESTS:-1}
RUN_DIST=${RUN_DIST:-0}

MESON_ARGS=("$@")

if [ ! -d "$BUILD_DIR/meson-private" ]; then
  meson setup "$BUILD_DIR" \
    --buildtype="$BUILD_TYPE" \
    --prefix="$PREFIX" \
    "${MESON_ARGS[@]}"
else
  meson setup "$BUILD_DIR" \
    --reconfigure \
    --buildtype="$BUILD_TYPE" \
    --prefix="$PREFIX" \
    "${MESON_ARGS[@]}"
fi

ninja -C "$BUILD_DIR"

if [ "$RUN_TESTS" = "1" ]; then
  ninja -C "$BUILD_DIR" test
fi

if [ "$RUN_DIST" = "1" ]; then
  meson dist -C "$BUILD_DIR"
fi

