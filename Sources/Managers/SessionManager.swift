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
        let allSessions = loadAllSessions(using: parser)
        return getActiveSessions(allSessions)
    }

    /// Parse all logs and return ALL sessions (for auto-calibration)
    /// - Parameter parser: JSONLParser instance
    /// - Returns: Array of all Session objects
    func loadAllSessions(using parser: JSONLParser) -> [Session] {
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
        return buildSessions(from: allEntries)
    }

    /// Calculate the current clock-aligned 5-hour block's token total
    /// - Parameter parser: JSONLParser instance
    /// - Returns: Total tokens in the current 5-hour block
    func getCurrentBlockTokens(using parser: JSONLParser) -> Double {
        var allEntries: [LogEntry] = []
        
        // Find all project directories and parse all JSONL files
        let projectDirs = JSONLParser.findProjectDirectories()
        for projectDir in projectDirs {
            do {
                let fileEntries = try parser.parseDirectory(directoryURL: projectDir)
                for (_, entries) in fileEntries {
                    allEntries.append(contentsOf: entries)
                }
            } catch {
                // Skip errors
            }
        }
        
        // Filter for assistant messages with usage data
        let assistantEntries = allEntries.filter { $0.isAssistantWithUsage }
        
        // Calculate the current block boundaries
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let blockHour = (hour / 5) * 5  // 0, 5, 10, 15, 20
        
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = blockHour
        components.minute = 0
        components.second = 0
        
        guard let blockStart = calendar.date(from: components) else { return 0 }
        let blockEnd = blockStart.addingTimeInterval(5 * 60 * 60)
        
        // Sum tokens for entries in the current block
        var totalTokens: Double = 0
        for entry in assistantEntries {
            guard let entryDate = entry.date,
                  entryDate >= blockStart,
                  entryDate < blockEnd else { continue }
            totalTokens += entry.totalTokensWithCache
        }
        
        return totalTokens
    }

    /// Find the maximum tokens used in any clock-aligned 5-hour block (like ccusage)
    /// - Parameter parser: JSONLParser instance
    /// - Returns: Maximum tokens with cache found in any 5-hour block
    func findMaxHistoricalTokens(using parser: JSONLParser) -> Double {
        var allEntries: [LogEntry] = []
        
        // Find all project directories and parse all JSONL files
        let projectDirs = JSONLParser.findProjectDirectories()
        for projectDir in projectDirs {
            do {
                let fileEntries = try parser.parseDirectory(directoryURL: projectDir)
                for (_, entries) in fileEntries {
                    allEntries.append(contentsOf: entries)
                }
            } catch {
                // Skip errors
            }
        }
        
        // Filter for assistant messages with usage data
        let assistantEntries = allEntries.filter { $0.isAssistantWithUsage }
        
        // Group entries into clock-aligned 5-hour blocks (like ccusage)
        var blockTotals: [String: Double] = [:]
        
        for entry in assistantEntries {
            guard let entryDate = entry.date else { continue }
            
            // Calculate the block ID (clock-aligned 5-hour window)
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: entryDate)
            let blockHour = (hour / 5) * 5  // 0, 5, 10, 15, 20
            
            // Create block start time
            var components = calendar.dateComponents([.year, .month, .day], from: entryDate)
            components.hour = blockHour
            components.minute = 0
            components.second = 0
            
            guard let blockStart = calendar.date(from: components) else { continue }
            let blockId = ISO8601DateFormatter().string(from: blockStart)
            
            // Sum all token types (input + output + cacheCreation + cacheRead)
            blockTotals[blockId, default: 0] += entry.totalTokensWithCache
        }
        
        // Find the max block total
        let maxTokens = blockTotals.values.max() ?? 0
        print("Found \(blockTotals.count) historical blocks, max tokens: \(String(format: "%.0f", maxTokens))")
        return maxTokens
    }
}
