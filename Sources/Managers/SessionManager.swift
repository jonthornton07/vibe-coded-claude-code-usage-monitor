import Foundation

/// Manages Claude Code sessions and calculates 5-hour rolling windows
class SessionManager {
    /// Gap threshold for detecting new session windows (5 hours + buffer)
    private static let sessionGapThreshold: TimeInterval = 5.5 * 60 * 60

    /// Build sessions from log entries, splitting on large gaps
    /// - Parameter entries: All log entries from all files
    /// - Returns: Array of Session objects
    func buildSessions(from entries: [LogEntry]) -> [Session] {
        // Filter for assistant messages with usage data
        let assistantEntries = entries.filter { $0.isAssistantWithUsage }

        // Group by session ID
        let grouped = Dictionary(grouping: assistantEntries) { entry in
            entry.sessionId ?? "unknown"
        }

        var sessions: [Session] = []

        for (sessionId, sessionEntries) in grouped {
            // Sort entries by timestamp
            let sortedEntries = sessionEntries
                .compactMap { entry -> (Date, LogEntry)? in
                    guard let date = entry.date else { return nil }
                    return (date, entry)
                }
                .sorted { $0.0 < $1.0 }

            guard !sortedEntries.isEmpty else {
                continue
            }

            // Split into separate session windows based on gaps
            var currentWindowStart: Date? = nil
            var currentWindowEntries: [LogEntry] = []
            var windowCount = 0

            for (entryDate, entry) in sortedEntries {
                if let windowStart = currentWindowStart {
                    let timeSinceWindowStart = entryDate.timeIntervalSince(windowStart)
                    let timeSinceLastEntry = currentWindowEntries.last.flatMap { lastEntry in
                        lastEntry.date.flatMap { entryDate.timeIntervalSince($0) }
                    } ?? 0

                    // Check if we should start a new window
                    // Either: entry is outside 5-hour window OR there's a large gap
                    if timeSinceWindowStart >= Session.sessionDuration ||
                       timeSinceLastEntry > Self.sessionGapThreshold {
                        // Save current window as a session
                        if !currentWindowEntries.isEmpty {
                            windowCount += 1
                            let session = Session(
                                sessionId: sessionId,
                                startTime: windowStart,
                                entries: currentWindowEntries
                            )
                            print("  Created window #\(windowCount) for \(sessionId): \(currentWindowEntries.count) entries, \(String(format: "%.0f", session.totalTokens)) tokens")
                            sessions.append(session)
                        }

                        // Start new window
                        currentWindowStart = entryDate
                        currentWindowEntries = [entry]
                    } else {
                        // Add to current window
                        currentWindowEntries.append(entry)
                    }
                } else {
                    // Start first window
                    currentWindowStart = entryDate
                    currentWindowEntries = [entry]
                }
            }

            // Don't forget the last window
            if !currentWindowEntries.isEmpty, let windowStart = currentWindowStart {
                windowCount += 1
                let session = Session(
                    sessionId: sessionId,
                    startTime: windowStart,
                    entries: currentWindowEntries
                )
                print("  Created window #\(windowCount) for \(sessionId): \(currentWindowEntries.count) entries, \(String(format: "%.0f", session.totalTokens)) tokens")
                sessions.append(session)
            }
        }

        return sessions
    }

    /// Get only active sessions (within 5 hours of now)
    /// - Parameter sessions: All sessions
    /// - Returns: Array of active Session objects
    func getActiveSessions(_ sessions: [Session]) -> [Session] {
        sessions.filter { $0.isActive }
    }

    /// Parse all logs and return active sessions
    /// - Parameter parser: JSONLParser instance
    /// - Returns: Array of active Session objects
    func loadActiveSessions(using parser: JSONLParser) -> [Session] {
        var allEntries: [LogEntry] = []

        // Find all project directories
        let projectDirs = JSONLParser.findProjectDirectories()

        // Parse all JSONL files
        for projectDir in projectDirs {
            do {
                let fileEntries = try parser.parseDirectory(directoryURL: projectDir)
                for (_, entries) in fileEntries {
                    allEntries.append(contentsOf: entries)
                }
            } catch {
                print("Error parsing directory \(projectDir.lastPathComponent): \(error)")
            }
        }

        // Build all sessions
        let allSessions = buildSessions(from: allEntries)

        // Return only active ones
        return getActiveSessions(allSessions)
    }
}
