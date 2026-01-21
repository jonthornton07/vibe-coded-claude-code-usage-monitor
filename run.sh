#!/bin/bash

# Build and run Claude Code Monitor

echo "Building Claude Code Monitor..."
swift build -c release

if [ $? -eq 0 ]; then
    echo "Starting Claude Code Monitor..."
    echo "The app will appear in your menu bar."
    echo "Press Ctrl+C to quit."
    ./.build/release/ClaudeCodeMonitor
else
    echo "Build failed!"
    exit 1
fi
