import XCTest
@testable import ClaudeCodeMonitor

final class SessionManagerTests: XCTestCase {
    var sessionManager: SessionManager!

    override func setUp() {
        super.setUp()
        sessionManager = SessionManager()
    }

    func testBuildSessionsFromEntries() {
        let now = Date()
        let formatter = ISO8601DateFormatter()

        let entries = [
            createLogEntry(sessionId: "session1", timestamp: formatter.string(from: now.addingTimeInterval(-3600)), tokens: 100),
            createLogEntry(sessionId: "session1", timestamp: formatter.string(from: now.addingTimeInterval(-1800)), tokens: 200),
            createLogEntry(sessionId: "session2", timestamp: formatter.string(from: now.addingTimeInterval(-7200)), tokens: 300)
        ]

        let sessions = sessionManager.buildSessions(from: entries)

        XCTAssertEqual(sessions.count, 2)
        XCTAssertTrue(sessions.contains { $0.sessionId == "session1" })
        XCTAssertTrue(sessions.contains { $0.sessionId == "session2" })
    }

    func testActiveSessionFiltering() {
        let now = Date()
        let formatter = ISO8601DateFormatter()

        // Active session (1 hour ago)
        let activeEntry = createLogEntry(
            sessionId: "active",
            timestamp: formatter.string(from: now.addingTimeInterval(-3600)),
            tokens: 100
        )

        // Expired session (6 hours ago)
        let expiredEntry = createLogEntry(
            sessionId: "expired",
            timestamp: formatter.string(from: now.addingTimeInterval(-6 * 3600)),
            tokens: 100
        )

        let allSessions = sessionManager.buildSessions(from: [activeEntry, expiredEntry])
        let activeSessions = sessionManager.getActiveSessions(allSessions)

        XCTAssertEqual(activeSessions.count, 1)
        XCTAssertEqual(activeSessions.first?.sessionId, "active")
    }

    func test5HourWindowFiltering() {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        let sessionStart = now.addingTimeInterval(-3600) // 1 hour ago

        // Entries within 5 hour window
        let entry1 = createLogEntry(sessionId: "test", timestamp: formatter.string(from: sessionStart), tokens: 100)
        let entry2 = createLogEntry(sessionId: "test", timestamp: formatter.string(from: sessionStart.addingTimeInterval(3600)), tokens: 200)
        let entry3 = createLogEntry(sessionId: "test", timestamp: formatter.string(from: sessionStart.addingTimeInterval(4 * 3600)), tokens: 300)

        // Entry outside 5 hour window (6 hours from start)
        let entry4 = createLogEntry(sessionId: "test", timestamp: formatter.string(from: sessionStart.addingTimeInterval(6 * 3600)), tokens: 400)

        let sessions = sessionManager.buildSessions(from: [entry1, entry2, entry3, entry4])

        XCTAssertEqual(sessions.count, 1)
        let session = sessions.first!
        XCTAssertEqual(session.entries.count, 3) // Should not include entry4
    }

    // Helper to create log entries for testing
    private func createLogEntry(sessionId: String, timestamp: String, tokens: Int) -> LogEntry {
        let usage = LogEntry.Usage(
            inputTokens: tokens,
            cacheCreationInputTokens: 0,
            cacheReadInputTokens: 0,
            outputTokens: 0
        )

        let message = LogEntry.Message(role: "assistant", usage: usage)

        return LogEntry(
            type: "assistant",
            timestamp: timestamp,
            sessionId: sessionId,
            message: message,
            uuid: UUID().uuidString
        )
    }
}
