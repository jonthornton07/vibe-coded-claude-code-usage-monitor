.PHONY: setup build release install uninstall clean test run help

BINARY_NAME = ClaudeCodeMonitor
INSTALL_PATH = /usr/local/bin

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  setup     Check and install dependencies (ccusage)"
	@echo "  build     Build debug version"
	@echo "  release   Build release version"
	@echo "  install   Build and install to $(INSTALL_PATH)"
	@echo "  uninstall Remove from $(INSTALL_PATH)"
	@echo "  run       Build and run debug version"
	@echo "  test      Run tests"
	@echo "  clean     Remove build artifacts"

setup:
	@echo "Checking dependencies..."
	@command -v npx >/dev/null 2>&1 || { echo "Error: npm/npx is required. Install Node.js first."; exit 1; }
	@npx ccusage --version >/dev/null 2>&1 || { echo "Installing ccusage..."; npm install -g ccusage; }
	@echo "Dependencies OK"

build: setup
	swift build

release: setup
	swift build -c release

install: release
	@echo "Installing to $(INSTALL_PATH)/$(BINARY_NAME)..."
	@mkdir -p $(INSTALL_PATH)
	cp .build/release/$(BINARY_NAME) $(INSTALL_PATH)/$(BINARY_NAME)
	@echo "Installed successfully"

uninstall:
	@echo "Removing $(INSTALL_PATH)/$(BINARY_NAME)..."
	rm -f $(INSTALL_PATH)/$(BINARY_NAME)
	@echo "Uninstalled"

run: build
	.build/debug/$(BINARY_NAME)

test: setup
	swift test

clean:
	swift package clean
	rm -rf .build
