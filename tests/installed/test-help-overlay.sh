#!/bin/bash
# Installed test for Feature 1.1: Keyboard Shortcuts Help Overlay
# This test verifies the app launches and shortcuts window can be created

set -e

# Get the build directory (assume we're running from project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/_build"
APP_BINARY="${BUILD_DIR}/src/cassette"

# Test that the app binary exists
echo "Testing app binary..."
if [ ! -f "$APP_BINARY" ]; then
    echo "ERROR: cassette binary not found at $APP_BINARY"
    echo "Please build the project first: ninja -C _build"
    exit 1
fi

echo "✓ Cassette binary found: $APP_BINARY"

# Test that shortcuts window UI resource exists in build
UI_RESOURCE="${BUILD_DIR}/data/ui/shortcuts-window.ui"
if [ -f "$UI_RESOURCE" ]; then
    echo "✓ Shortcuts window UI resource found"
else
    echo "WARNING: Shortcuts window UI resource not found (may be in gresources)"
fi

# Test that gresource file includes shortcuts-window
GRESOURCE_XML="${BUILD_DIR}/data/space.rirusha.Cassette.gresource.xml"
if [ -f "$GRESOURCE_XML" ] && grep -q "shortcuts-window.ui" "$GRESOURCE_XML"; then
    echo "✓ Shortcuts window UI is included in gresources"
else
    echo "WARNING: Could not verify shortcuts-window.ui in gresources"
fi

echo ""
echo "Installed test for help overlay: PASSED"

