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

# Build with Swift Package Manager
swift build -c release

# Run the app
.build/release/ClaudeCodeMonitor
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

Tokens are calculated using the formula:
```
total = input_tokens + cache_creation_input_tokens + output_tokens + (cache_read_input_tokens * 0.1)
```

Cache read tokens are counted at 10% cost (90% discount) per Anthropic's prompt caching pricing.

### Color Indicators

- **Green** (< 70%): Normal usage
- **Yellow** (70-90%): Approaching limit
- **Red** (> 90%): Critical usage

## Requirements

- macOS 13.0 or later
- Swift 5.9 or later
- Claude Code installed with logs at `~/.claude/projects/`

## How It Works

The app:
1. Monitors `~/.claude/projects/` for changes using FSEvents
2. Parses JSONL log files to extract token usage
3. Groups entries by session ID and calculates 5-hour windows
4. Sums all active sessions and displays in the menu bar
5. Updates automatically when new messages are logged

## Project Structure

```
Sources/
├── main.swift                      # App entry point
├── Models/
│   ├── LogEntry.swift             # JSONL log entry model
│   ├── Session.swift              # 5-hour session model
│   └── UsageData.swift            # Aggregated usage data
├── Parsers/
│   └── JSONLParser.swift          # JSONL file parser
├── Managers/
│   ├── SessionManager.swift       # Session grouping logic
│   └── UsageCalculator.swift     # Token calculation
├── Monitoring/
│   └── FileMonitor.swift          # FSEvents file watcher
└── UI/
    └── StatusBarController.swift  # Menu bar UI
```

## Development

### Running in Development

```bash
swift run
```

### Running Tests

```bash
swift test
```

### Creating a Release Build

```bash
swift build -c release
```

The compiled binary will be at `.build/release/ClaudeCodeMonitor`.

## Roadmap

Future enhancements:
- [ ] Preferences window for plan selection (Pro/Max5/Max20/Custom)
- [ ] Notifications when approaching token limit
- [ ] Historical usage graphs
- [ ] Per-project usage filtering
- [ ] Model-specific breakdown (Sonnet vs Opus)
- [ ] Launch at login option
- [ ] App icon and branding

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Inspired by [ccusage](https://github.com/ryoppippi/ccusage)
- Built for the Claude Code community
