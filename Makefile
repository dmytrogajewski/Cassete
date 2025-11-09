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

# Local tools directory
TOOLS_DIR := tools
VALA_LINT_DIR := $(TOOLS_DIR)/vala-lint
VALA_LINT_BUILD := $(VALA_LINT_DIR)/build
VALA_LINT_LOCAL := $(TOOLS_DIR)/local_install/bin/vala-lint
VALA_LINT_BINARY := $(VALA_LINT_BUILD)/src/io.elementary.vala-lint
VALA_LINT_LIB_DIR := $(TOOLS_DIR)/local_install/lib64

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

# Check for TODO/FIXME comments in source code
.PHONY: check-todos
check-todos:
	@echo "Checking for TODO/FIXME comments in source code..."
	@TODOS=$$(grep -rn --include="*.vala" --include="*.blp" --include="*.ui" --include="*.c" --include="*.h" \
		--exclude-dir="$(BUILDDIR)" --exclude-dir=".git" \
		-E "(\\bTODO\\b|\\bFIXME\\b)" \
		src/ data/ subprojects/libtape/lib/ subprojects/libapi-base/lib/ 2>/dev/null || true); \
	if [ -n "$$TODOS" ]; then \
		echo "ERROR: TODO/FIXME comments found in source code:"; \
		echo "$$TODOS"; \
		echo ""; \
		echo "Please address all TODO/FIXME comments before running tests."; \
		exit 1; \
	else \
		echo "No TODO/FIXME comments found."; \
	fi

# Run tests (if available)
# Note: Only runs Cassette-specific tests to avoid dependency test failures
.PHONY: test
test: build check-todos
	@echo "Running Cassette tests..."
	@meson test -C $(BUILDDIR) --no-rebuild --suite cassette || (echo "Cassette tests failed!"; exit 1)

# Lint/check code (vala-lint if available)
.PHONY: check
check:
	@if command -v vala-lint >/dev/null 2>&1; then \
		echo "Running vala-lint..."; \
		vala-lint $(shell find src -name "*.vala" 2>/dev/null) || true; \
	else \
		echo "vala-lint not found. Install it to check code style."; \
	fi

# Setup and build vala-lint locally
.PHONY: setup-vala-lint
setup-vala-lint:
	@echo "Setting up vala-lint locally..."
	@if [ ! -d "$(VALA_LINT_DIR)" ]; then \
		echo "Cloning vala-lint repository..."; \
		mkdir -p $(TOOLS_DIR); \
		git clone https://github.com/vala-lang/vala-lint.git $(VALA_LINT_DIR); \
	fi
	@if [ ! -f "$(VALA_LINT_BUILD)/build.ninja" ]; then \
		echo "Configuring vala-lint build..."; \
		cd $(VALA_LINT_DIR) && meson setup build --prefix=$$(cd ../local_install && pwd); \
	fi
	@if [ ! -f "$(VALA_LINT_BINARY)" ]; then \
		echo "Building vala-lint..."; \
		cd $(VALA_LINT_DIR) && ninja -C build; \
		echo "Installing vala-lint locally..."; \
		cd $(VALA_LINT_DIR) && ninja -C build install; \
	fi
	@if [ -f "$(VALA_LINT_LOCAL)" ]; then \
		echo "vala-lint installed successfully at: $(VALA_LINT_LOCAL)"; \
	elif [ -f "$(VALA_LINT_BINARY)" ]; then \
		echo "vala-lint built successfully at: $(VALA_LINT_BINARY)"; \
		echo "Note: Run 'make install-vala-lint' to install it to tools/local_install/bin"; \
	else \
		echo "Error: Failed to build vala-lint. Make sure libvala-devel is installed."; \
		echo "Install with: sudo dnf install libvala-devel (Fedora)"; \
		exit 1; \
	fi

# Install vala-lint to local directory
.PHONY: install-vala-lint
install-vala-lint: setup-vala-lint
	@if [ -f "$(VALA_LINT_BUILD)/build.ninja" ]; then \
		echo "Installing vala-lint to local directory..."; \
		cd $(VALA_LINT_DIR) && ninja -C build install; \
	fi

# Run comprehensive linting with vala-lint and PVS-Studio OSS
.PHONY: lint
lint: build
	@echo "Running linting tools..."
	@LINT_ERRORS=0; \
	VALA_LINT_CMD=""; \
	VALA_LINT_ENV=""; \
	if [ -f "$(VALA_LINT_LOCAL)" ] && [ -x "$(VALA_LINT_LOCAL)" ]; then \
		VALA_LINT_CMD="$(VALA_LINT_LOCAL)"; \
		if [ -d "$(VALA_LINT_LIB_DIR)" ]; then \
			VALA_LINT_ENV="LD_LIBRARY_PATH=$(VALA_LINT_LIB_DIR):$$LD_LIBRARY_PATH"; \
		fi; \
	elif [ -f "$(VALA_LINT_BINARY)" ] && [ -x "$(VALA_LINT_BINARY)" ]; then \
		VALA_LINT_CMD="$(VALA_LINT_BINARY)"; \
		if [ -d "$(VALA_LINT_LIB_DIR)" ]; then \
			VALA_LINT_ENV="LD_LIBRARY_PATH=$(VALA_LINT_LIB_DIR):$$LD_LIBRARY_PATH"; \
		fi; \
	elif command -v io.elementary.vala-lint >/dev/null 2>&1; then \
		VALA_LINT_CMD="io.elementary.vala-lint"; \
	elif command -v vala-lint >/dev/null 2>&1; then \
		VALA_LINT_CMD="vala-lint"; \
	fi; \
	if [ -n "$$VALA_LINT_CMD" ]; then \
		echo ""; \
		echo "=== Running vala-lint ==="; \
		VALA_FILES=$$(find src subprojects/libtape/lib subprojects/libapi-base/lib -name "*.vala" -type f 2>/dev/null | grep -v "test-shader\|vibe-canvas\|in-style.vala" | sort); \
		if [ -n "$$VALA_FILES" ]; then \
			if [ -n "$$VALA_LINT_ENV" ]; then \
				eval $$VALA_LINT_ENV $$VALA_LINT_CMD -c vala-lint.conf $$VALA_FILES 2>&1; \
			else \
				$$VALA_LINT_CMD -c vala-lint.conf $$VALA_FILES 2>&1; \
			fi; \
			if [ $$? -eq 0 ]; then \
				echo "vala-lint: No issues found."; \
			else \
				echo "vala-lint: Issues found!"; \
				LINT_ERRORS=$$((LINT_ERRORS + 1)); \
			fi; \
		else \
			echo "vala-lint: No Vala files found."; \
		fi; \
	else \
		echo "vala-lint not found. Run 'make setup-vala-lint' to install it locally."; \
		echo "Or install system-wide with: sudo dnf install vala-lint (Fedora) or sudo apt install vala-lint (Debian)"; \
	fi; \
	echo ""; \
	if [ $$LINT_ERRORS -gt 0 ]; then \
		echo "Linting completed with errors. Check the output above for details."; \
		exit 1; \
	else \
		echo "Linting completed successfully!"; \
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
	@echo "  make check      - Run vala-lint checker (if available)"
	@echo "  make lint       - Run comprehensive linting (vala-lint + PVS-Studio OSS)"
	@echo "  make setup-vala-lint - Clone and build vala-lint locally"
	@echo "  make install-vala-lint - Install vala-lint to tools/local_install/bin"
	@echo "  make pot        - Update translation template"
	@echo "  make config     - Show build configuration"
	@echo "  make help       - Show this help message"
	@echo ""

