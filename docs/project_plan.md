# Claude Code Usage Monitor

## macOS Status Bar App - Project Plan

**Version 1.0**  
**Date:** January 12, 2026

---

## Executive Summary

A native macOS status bar application that monitors Claude Code token usage in real-time, helping Pro plan users track consumption against their 44,000 token per 5-hour session limit. The app will parse local JSONL log files, calculate rolling session windows, and provide at-a-glance visibility without context switching.

---

## Project Overview

### Problem Statement

Claude Code Pro users have a 44,000 token limit per 5-hour session, but have no built-in way to monitor their usage without using third-party CLI tools or the /context command. This creates uncertainty and can lead to unexpected session terminations mid-work.

### Solution

Build a lightweight native macOS status bar app that continuously monitors Claude Code usage by reading local log files and displaying current token consumption, percentage of limit used, and session information directly in the menu bar.

### Success Criteria

- Real-time token usage visible in status bar without opening any windows
- Accurate calculation of 5-hour rolling session windows
- Visual indicators (color coding) for usage levels
- Less than 5MB memory footprint, minimal CPU usage

---

## Technical Architecture

### Technology Stack

- **Language:** Swift
- **UI Framework:** SwiftUI for menu bar interface
- **File Monitoring:** FSEvents API for watching log directory
- **Data Parsing:** Swift's native JSON decoder for JSONL files
- **Background Processing:** Dispatch queues for file I/O

### Core Components

1. **FileMonitor:** Watches `~/.claude/projects/` for changes using FSEvents
2. **LogParser:** Reads and parses JSONL log files, extracts token usage data
3. **SessionManager:** Calculates 5-hour rolling windows, tracks active sessions
4. **UsageCalculator:** Aggregates token counts, computes percentages and burn rates
5. **StatusBarController:** Manages menu bar icon, text, and dropdown menu
6. **PreferencesManager:** Handles user settings and plan configuration

### Data Model

Claude Code logs are stored as JSONL (JSON Lines) files in `~/.claude/projects/`. Each line contains a JSON object with fields including:

- `timestamp`: ISO 8601 datetime
- `input_tokens`: Number of tokens in the prompt
- `output_tokens`: Number of tokens in the response
- `cache_creation_tokens`: Tokens used for cache creation
- `cache_read_tokens`: Tokens read from cache
- `model`: Claude model used (sonnet-4, opus-4, etc.)

---

## Features & Development Milestones

### Phase 1: MVP (Target: 2 weeks)

#### Week 1: Core Functionality

- Set up Swift project with menu bar app template
- Implement JSONL parser for Claude Code log files
- Build 5-hour rolling session window calculator
- Create basic token aggregation logic

#### Week 2: UI & Polish

- Design and implement status bar icon with token count
- Create dropdown menu with session details
- Implement color-coded status indicator (green/yellow/red)
- Add file system monitoring with FSEvents
- Test with real Claude Code usage data

#### MVP Features:

- Display current token usage in menu bar (e.g., "12.5k/44k")
- Show percentage used with color coding
- Display session start time and time remaining
- Show tokens remaining until limit
- Auto-refresh on log file changes

### Phase 2: Enhanced Features (Target: 1-2 weeks)

- User preferences panel for plan selection (Pro/Max5/Max20/Custom)
- Notifications when approaching limit (80%, 90%, 95%)
- Multiple active session tracking
- Token burn rate calculation (tokens/minute)
- Estimated time until limit based on burn rate
- Launch at login option

### Phase 3: Advanced Features (Future)

- Historical usage graphs (daily/weekly/monthly)
- Per-project usage tracking and filtering
- Model-specific breakdown (Sonnet vs Opus usage)
- Export usage data to CSV/JSON
- Integration with Shortcuts.app for automation
- Widget support for macOS notification center

---

## Implementation Details

### 5-Hour Rolling Window Algorithm

Claude Code uses 5-hour rolling sessions where each session starts with the first message and expires exactly 5 hours later. Multiple overlapping sessions can be active simultaneously.

1. Parse all log entries and extract timestamps
2. Group entries into sessions based on first message timestamp
3. For each session, sum all tokens within the 5-hour window
4. Identify currently active sessions (within 5 hours of now)
5. Display the session with highest usage or most recent activity

### File Monitoring Strategy

- Use FSEvents to watch `~/.claude/projects/` for changes
- Debounce file changes to avoid excessive parsing (500ms delay)
- Parse only changed files, not entire directory on each update
- Cache parsed data in memory with last-modified timestamps
- Fallback to polling if FSEvents fails (every 5 seconds)

### Performance Optimization

- Process file I/O on background dispatch queue
- Update UI on main queue only when data changes
- Limit memory usage by keeping only last 7 days of log data
- Use streaming JSON parser for large JSONL files
- Target: <5MB memory, <1% CPU when idle, <5% during updates

---

## UI/UX Design

### Status Bar Display

- **Icon:** Circular gauge or simple "CC" monogram
- **Text format:** "12.5k" or "28%" (user configurable)
- **Color coding:** Green (<70%), Yellow (70-90%), Red (>90%)

### Dropdown Menu Layout

#### Section 1: Current Session

- Tokens used: 12,345 / 44,000 (28%)
- Session started: 2:30 PM
- Time remaining: 3h 15m
- Burn rate: 125 tokens/min

#### Section 2: Quick Actions

- Refresh usage data
- Open log directory
- Preferences

#### Section 3: App Actions

- About
- Quit

---

## Testing Strategy

### Unit Tests

- JSONL parsing with various log formats
- 5-hour session window calculations
- Token aggregation logic
- Burn rate calculations

### Integration Tests

- File monitoring with simulated log updates
- Multiple concurrent sessions
- Memory and CPU performance under load

### Manual Testing

- Real-world usage during actual Claude Code sessions
- UI responsiveness and visual accuracy
- Edge cases: empty logs, corrupted files, missing directories
- Battery impact testing on MacBook

---

## Risks & Mitigation

| Risk                            | Impact                  | Mitigation                                                 |
| ------------------------------- | ----------------------- | ---------------------------------------------------------- |
| Claude Code log format changes  | App breaks with updates | Build robust parser with fallbacks; monitor Anthropic docs |
| High memory/CPU usage           | Poor user experience    | Optimize with background queues, limit data retention      |
| Inaccurate session calculations | User loses trust in app | Extensive testing with real data; compare against ccusage  |
| File permissions issues         | Can't read log files    | Clear error messages; guide user to grant permissions      |

---

## Key Technical Decisions

### Why Swift over Python/Node.js?

- Native performance with minimal overhead
- No external runtime dependencies
- Better macOS integration (status bar, FSEvents, notifications)
- Can distribute as single .app bundle

### Why not use ccusage as a library?

- ccusage is CLI-focused, not designed for background monitoring
- Native Swift gives better control over performance and UI
- Can reference ccusage source code for algorithm validation

### Data Storage Strategy

Use in-memory caching with periodic refresh from log files. No separate database needed for MVP. User preferences stored in UserDefaults.

---

## Distribution & Deployment

### Phase 1: Personal Use

- Build and run locally from Xcode
- Test on personal machine with real usage

### Phase 2: GitHub Release

- Open source the project on GitHub
- Provide pre-built .app bundle for download
- Document installation and usage in README
- Accept community contributions and feedback

### Phase 3: Homebrew (Optional)

- Create Homebrew cask for easy installation
- `brew install --cask claude-code-monitor`

---

## Resources & Timeline

| Phase   | Timeline  | Effort      |
| ------- | --------- | ----------- |
| MVP     | 2 weeks   | 15-20 hours |
| Phase 2 | 1-2 weeks | 10-15 hours |
| Phase 3 | As needed | Variable    |

### Required Skills

- Swift programming (you have experience)
- SwiftUI for UI (basic level sufficient for MVP)
- Basic understanding of JSON parsing
- File system operations and monitoring

---

## Success Metrics

### MVP Success

- App runs continuously without crashes for 7+ days
- Token counts match manual verification within 1%
- Updates appear within 2 seconds of log file changes
- Memory usage stays under 10MB

### Long-term Success

- Daily personal use becomes habitual
- Prevents at least one session limit surprise per week
- If open-sourced: 10+ GitHub stars, 2+ community contributions
- Continues working after Claude Code updates

---

## Next Steps

### Immediate Actions

1. Examine Claude Code log files to understand exact format
2. Set up new Swift project in Xcode with menu bar template
3. Build prototype JSONL parser
4. Implement 5-hour session window logic with test data
5. Create basic status bar UI with hardcoded values

### Week 1 Deliverable

Working prototype that reads real log files and displays token count in status bar, even if refresh is manual.

### Week 2 Deliverable

Fully functional MVP with automatic updates, color coding, and detailed dropdown menu. Ready for daily personal use.

---

## Appendix

### Reference Resources

- ccusage GitHub: https://github.com/ryoppippi/ccusage
- Claude-Code-Usage-Monitor: https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor
- Claude Code docs: https://code.claude.com/docs
- Apple FSEvents documentation

### Potential Project Names

- ClaudeMeter
- CodeUsageBar
- TokenWatch
- CCMonitor
- ClaudeGauge
