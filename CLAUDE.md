# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A native macOS status bar application that monitors Claude Code token usage in real-time by parsing local JSONL log files from `~/.claude/projects/`. The app displays current token consumption against the 44,000 token per 5-hour session limit for Pro plan users.

## Technology Stack

- **Language:** Swift
- **UI Framework:** SwiftUI for menu bar interface
- **File Monitoring:** FSEvents API for watching log directory
- **Data Parsing:** Swift's native JSON decoder for JSONL files
- **Background Processing:** Dispatch queues for file I/O

## Core Architecture Components

### 1. FileMonitor
Watches `~/.claude/projects/` for changes using FSEvents. Should debounce file changes (500ms delay) to avoid excessive parsing. Parse only changed files, not entire directory on each update. Fallback to polling (every 5 seconds) if FSEvents fails.

### 2. LogParser
Reads and parses JSONL (JSON Lines) log files. Each line is a JSON object with:
- `timestamp`: ISO 8601 datetime
- `input_tokens`: Number of tokens in the prompt
- `output_tokens`: Number of tokens in the response
- `cache_creation_tokens`: Tokens used for cache creation
- `cache_read_tokens`: Tokens read from cache
- `model`: Claude model used (sonnet-4, opus-4, etc.)

### 3. SessionManager
Calculates 5-hour rolling windows. Claude Code uses 5-hour rolling sessions where each session starts with the first message and expires exactly 5 hours later. Multiple overlapping sessions can be active simultaneously.

Algorithm:
1. Parse all log entries and extract timestamps
2. Group entries into sessions based on first message timestamp
3. For each session, sum all tokens within the 5-hour window
4. Identify currently active sessions (within 5 hours of now)
5. Display the session with highest usage or most recent activity

### 4. UsageCalculator
Aggregates token counts, computes percentages against 44k limit, and calculates burn rates (tokens/minute).

### 5. StatusBarController
Manages menu bar icon, text display, and dropdown menu. Color coding: Green (<70%), Yellow (70-90%), Red (>90%).

### 6. PreferencesManager
Handles user settings stored in UserDefaults. Supports plan selection (Pro/Max5/Max20/Custom).

## Data Model & Storage Strategy

Use in-memory caching with periodic refresh from log files. No separate database needed for MVP. Limit memory by keeping only last 7 days of log data. Cache parsed data with last-modified timestamps to avoid re-parsing unchanged files.

## Performance Requirements

- Memory usage: <5MB (target), <10MB (max)
- CPU: <1% when idle, <5% during updates
- Update latency: Display changes within 2 seconds of log file changes
- Use streaming JSON parser for large JSONL files
- Process file I/O on background dispatch queue
- Update UI on main queue only when data changes

## Reference Implementations

The algorithm can be validated against these existing tools:
- ccusage: https://github.com/ryoppippi/ccusage
- Claude-Code-Usage-Monitor: https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor

## Development Commands

Since this is a Swift/Xcode project, standard Xcode workflows apply:
- Build: Cmd+B in Xcode or `xcodebuild`
- Run: Cmd+R in Xcode
- Test: Cmd+U in Xcode or `xcodebuild test`

## Key Technical Decisions

**Why Swift over Python/Node.js?**
Native performance with minimal overhead, no external runtime dependencies, better macOS integration (status bar, FSEvents, notifications), and can distribute as single .app bundle.

**Robust parsing:** Build parser with fallbacks since Claude Code log format may change. Handle edge cases: empty logs, corrupted files, missing directories.

**Error handling:** Provide clear error messages if file permissions prevent reading log files. Guide user to grant necessary permissions.
