# Claude Code Monitor

A native macOS status bar app that monitors Claude Code token usage in real-time.

## Features

- **Real-time monitoring**: Displays current token usage in the menu bar
- **5-hour session tracking**: Accurately calculates rolling 5-hour session windows
- **Color-coded indicators**: Visual feedback based on usage levels (green/yellow/red)
- **Multi-session support**: Sums usage across all active Claude Code sessions
- **Auto-refresh**: Automatically updates when log files change
- **Lightweight**: Minimal memory and CPU usage

## Installation

### Build from source

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-usage-monitor-mac.git
cd claude-usage-monitor-mac

# Setup dependencies and build
make release

# Or install to /usr/local/bin
make install
```

## Configuration

### Custom Projects Directory

By default, the app monitors `~/.claude/projects/`. You can override this with the `CLAUDE_PROJECTS_PATH` environment variable:

```bash
# Use a custom directory
export CLAUDE_PROJECTS_PATH=/path/to/your/claude/projects
.build/release/ClaudeCodeMonitor

# Or set it inline
CLAUDE_PROJECTS_PATH=/path/to/test/data .build/release/ClaudeCodeMonitor
```

This is useful for:

- Testing with mock data
- Non-standard Claude installations
- Development and debugging

## Usage

The app runs as a menu bar application (no dock icon). Click the menu bar item to see:

- Total tokens used across all active sessions
- Usage percentage of 44,000 token limit
- Individual session details with time remaining
- Refresh option to manually update usage

### Token Calculation

Token usage is retrieved via [ccusage](https://github.com/ryoppippi/ccusage), which accurately parses Claude Code logs and handles token counting, including cache discounts.

### Color Indicators

- **Green** (< 70%): Normal usage
- **Yellow** (70-90%): Approaching limit
- **Red** (> 90%): Critical usage

## Requirements

- macOS 13.0 or later
- Swift 5.9 or later
- [ccusage](https://github.com/ryoppippi/ccusage) installed (`npm install -g ccusage`)
- Claude Code installed with logs at `~/.claude/projects/`

## How It Works

The app:

1. Monitors `~/.claude/projects/` for changes using FSEvents
2. Calls `ccusage` CLI to get accurate token usage data
3. Displays the active session's usage in the menu bar
4. Updates automatically when new messages are logged

## Project Structure

```
Sources/
├── main.swift                      # App entry point
├── Config.swift                    # Configuration constants
├── Models/
│   ├── LogEntry.swift             # JSONL log entry model
│   ├── Session.swift              # 5-hour session model
│   └── UsageData.swift            # Aggregated usage data
├── Parsers/
│   └── JSONLParser.swift          # JSONL file parser
├── Services/
│   └── CCUsageService.swift       # ccusage CLI wrapper
├── Managers/
│   ├── SessionManager.swift       # Session grouping logic
│   └── UsageCalculator.swift      # Token calculation
├── Monitoring/
│   └── FileMonitor.swift          # FSEvents file watcher
└── UI/
    └── StatusBarController.swift  # Menu bar UI
```

## Development

```bash
make help      # Show all available commands
make setup     # Check/install dependencies (ccusage)
make build     # Build debug version
make release   # Build release version
make run       # Build and run
make test      # Run tests
make install   # Install to /usr/local/bin
make clean     # Remove build artifacts
```

## Run at Login

To have the app start automatically when you log in:

1. Run `make install` to install the binary
2. Open **System Settings → General → Login Items**
3. Click **+** under "Open at Login"
4. Press `Cmd+Shift+G` and enter `/usr/local/bin/ClaudeCodeMonitor`
5. Click Add

The app will now start automatically on login and appear in your menu bar.

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Inspired by [ccusage](https://github.com/ryoppippi/ccusage)
- Built for the Claude Code community
