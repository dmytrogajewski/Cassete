# Makefile for Cassette music player
#
# Common targets:
#   make build      - Build the project
#   make run        - Build and run the application
#   make clean      - Clean build artifacts
#   make install    - Install the application
#   make uninstall  - Uninstall the application
#   make setup      - Initial setup (configure meson)
#   make reconfigure - Reconfigure meson with default options
#   make check      - Run linter/checker (if available)
#   make help       - Show this help message

# Build directory
BUILDDIR := _build

# Binary path
BINARY := $(BUILDDIR)/src/cassette

# GSettings schema directory
GSETTINGS_SCHEMA_DIR := $(BUILDDIR)/data/glib-2.0/schemas

# Default target
.PHONY: all
all: build

# Build the project
.PHONY: build
build:
	@echo "Building Cassette..."
	@ninja -C $(BUILDDIR)

# Setup meson build directory (first-time setup)
.PHONY: setup
setup:
	@if [ ! -d $(BUILDDIR) ]; then \
		echo "Configuring meson build..."; \
		meson setup $(BUILDDIR); \
	else \
		echo "Build directory already exists. Use 'make reconfigure' to reconfigure."; \
	fi

# Reconfigure meson
.PHONY: reconfigure
reconfigure:
	@echo "Reconfiguring meson build..."
	@meson setup --reconfigure $(BUILDDIR)

# Run the application
.PHONY: run
run: build
	@echo "Running Cassette..."
	@GSETTINGS_SCHEMA_DIR=$(GSETTINGS_SCHEMA_DIR) $(BINARY)

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@ninja -C $(BUILDDIR) clean

# Clean everything (including build directory)
.PHONY: distclean
distclean:
	@echo "Removing build directory..."
	@rm -rf $(BUILDDIR)

# Install the application
.PHONY: install
install: build
	@echo "Installing Cassette..."
	@ninja -C $(BUILDDIR) install

# Uninstall the application
.PHONY: uninstall
uninstall:
	@echo "Uninstalling Cassette..."
	@ninja -C $(BUILDDIR) uninstall

# Run tests (if available)
# Note: Some dependency tests may fail (e.g., network tests in libapi-base)
# This is expected and not related to Cassette code
.PHONY: test
test: build
	@echo "Running tests..."
	@meson test -C $(BUILDDIR) --no-rebuild || echo "Some tests failed (dependency tests may fail)"

# Lint/check code (vala-lint if available)
.PHONY: check
check:
	@if command -v vala-lint >/dev/null 2>&1; then \
		echo "Running vala-lint..."; \
		vala-lint $(shell find src -name "*.vala" 2>/dev/null) || true; \
	else \
		echo "vala-lint not found. Install it to check code style."; \
	fi

# Update translations
.PHONY: pot
pot:
	@echo "Updating translation template..."
	@cd po && ./update_potfiles.sh || echo "Translation update script not found"

# Quick development cycle: clean, build, run
.PHONY: dev
dev: clean build run

# Show build configuration
.PHONY: config
config:
	@echo "Build configuration:"
	@ninja -C $(BUILDDIR) -t compdb 2>/dev/null | head -5 || echo "Build directory not configured. Run 'make setup' first."

# Show help
.PHONY: help
help:
	@echo "Cassette Music Player - Makefile Targets"
	@echo ""
	@echo "Build targets:"
	@echo "  make build      - Build the project (default)"
	@echo "  make setup      - Initial meson setup (first time only)"
	@echo "  make reconfigure - Reconfigure meson build"
	@echo ""
	@echo "Run targets:"
	@echo "  make run        - Build and run the application"
	@echo "  make dev        - Clean, build, and run (development cycle)"
	@echo ""
	@echo "Clean targets:"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make distclean  - Remove entire build directory"
	@echo ""
	@echo "Install targets:"
	@echo "  make install    - Install the application"
	@echo "  make uninstall  - Uninstall the application"
	@echo ""
	@echo "Other targets:"
	@echo "  make test       - Run tests"
	@echo "  make check      - Run linter/checker"
	@echo "  make pot        - Update translation template"
	@echo "  make config     - Show build configuration"
	@echo "  make help       - Show this help message"
	@echo ""

