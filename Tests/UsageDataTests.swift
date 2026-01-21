import XCTest
@testable import ClaudeCodeMonitor

final class UsageDataTests: XCTestCase {

    func testTotalTokensAcrossSessions() {
        let now = Date()
        let formatter = ISO8601DateFormatter()

        // Create two sessions with known token counts
        let session1Entries = [
            createLogEntry(timestamp: formatter.string(from: now.addingTimeInterval(-3600)), tokens: 100)
        ]
        let session1 = Session(sessionId: "session1", startTime: now.addingTimeInterval(-3600), entries: session1Entries)

        let session2Entries = [
            createLogEntry(timestamp: formatter.string(from: now.addingTimeInterval(-1800)), tokens: 200)
        ]
        let session2 = Session(sessionId: "session2", startTime: now.addingTimeInterval(-1800), entries: session2Entries)

        let usageData = UsageData(activeSessions: [session1, session2], lastUpdated: now)

        // Total should be 100 + 200 = 300
        XCTAssertEqual(usageData.totalTokens, 300.0, accuracy: 0.01)
    }

    func testUsagePercentageCalculation() {
        let now = Date()
        let formatter = ISO8601DateFormatter()

        let entries = [
            createLogEntry(timestamp: formatter.string(from: now), tokens: 22000) // 50% of 44k
        ]
        let session = Session(sessionId: "test", startTime: now, entries: entries)
        let usageData = UsageData(activeSessions: [session], lastUpdated: now)

        XCTAssertEqual(usageData.usagePercentage, 50.0, accuracy: 0.1)
    }

    func testUsageLevelNormal() {
        let usageData = createUsageData(totalTokens: 30000) // ~68%
        XCTAssertEqual(usageData.usageLevel, .normal)
    }

    func testUsageLevelWarning() {
        let usageData = createUsageData(totalTokens: 35200) // 80%
        XCTAssertEqual(usageData.usageLevel, .warning)
    }

    func testUsageLevelCritical() {
        let usageData = createUsageData(totalTokens: 40000) // ~91%
        XCTAssertEqual(usageData.usageLevel, .critical)
    }

    func testTokensFormatted() {
        let usageData1 = createUsageData(totalTokens: 5432)
        XCTAssertEqual(usageData1.tokensFormatted, "5.4k")

        let usageData2 = createUsageData(totalTokens: 12345)
        XCTAssertEqual(usageData2.tokensFormatted, "12k")

        let usageData3 = createUsageData(totalTokens: 999)
        XCTAssertEqual(usageData3.tokensFormatted, "1.0k")
    }

    func testStatusBarText() {
        let usageData = createUsageData(totalTokens: 12500)
        XCTAssertEqual(usageData.statusBarText, "12k/44k")
    }

    func testEmptyUsageData() {
        let usageData = UsageData.empty
        XCTAssertEqual(usageData.totalTokens, 0.0)
        XCTAssertEqual(usageData.activeSessions.count, 0)
        XCTAssertEqual(usageData.usageLevel, .normal)
    }

    // Helper functions
    private func createUsageData(totalTokens: Double) -> UsageData {
        let now = Date()
        let formatter = ISO8601DateFormatter()

        let entries = [
            createLogEntry(timestamp: formatter.string(from: now), tokens: Int(totalTokens))
        ]
        let session = Session(sessionId: "test", startTime: now, entries: entries)

        return UsageData(activeSessions: [session], lastUpdated: now)
    }

    private func createLogEntry(timestamp: String, tokens: Int) -> LogEntry {
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
            sessionId: "test",
            message: message,
            uuid: UUID().uuidString
        )
    }
}
