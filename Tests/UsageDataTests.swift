import XCTest
@testable import ClaudeCodeMonitor

final class UsageDataTests: XCTestCase {

    func testUsagePercentageCalculation() {
        // 50% usage: 7.5M of 15M tokens
        let usageData = createUsageData(currentTokens: 7_500_000, maxTokens: 15_000_000)
        XCTAssertEqual(usageData.usagePercentage, 50.0, accuracy: 0.1)
    }

    func testUsagePercentageZeroMax() {
        let usageData = createUsageData(currentTokens: 1000, maxTokens: 0)
        XCTAssertEqual(usageData.usagePercentage, 0.0)
    }

    func testUsageLevelNormal() {
        // 60% usage
        let usageData = createUsageData(currentTokens: 9_000_000, maxTokens: 15_000_000)
        XCTAssertEqual(usageData.usageLevel, .normal)
    }

    func testUsageLevelWarning() {
        // 80% usage
        let usageData = createUsageData(currentTokens: 12_000_000, maxTokens: 15_000_000)
        XCTAssertEqual(usageData.usageLevel, .warning)
    }

    func testUsageLevelCritical() {
        // 95% usage
        let usageData = createUsageData(currentTokens: 14_250_000, maxTokens: 15_000_000)
        XCTAssertEqual(usageData.usageLevel, .critical)
    }

    func testTokensFormatted() {
        let usageData1 = createUsageData(currentTokens: 5_432_000, maxTokens: 15_000_000)
        XCTAssertEqual(usageData1.tokensFormatted, "5.4M")

        let usageData2 = createUsageData(currentTokens: 12_345_000, maxTokens: 15_000_000)
        XCTAssertEqual(usageData2.tokensFormatted, "12.3M")
    }

    func testMaxTokensFormatted() {
        let usageData = createUsageData(currentTokens: 0, maxTokens: 14_600_000)
        XCTAssertEqual(usageData.maxTokensFormatted, "14.6M")
    }

    func testStatusBarText() {
        // 28.4% usage
        let usageData = createUsageData(currentTokens: 4_260_000, maxTokens: 15_000_000)
        XCTAssertEqual(usageData.statusBarText, "28.4%")
    }

    func testTimeRemainingFormatted() {
        // 2 hours 30 minutes
        let usageData = UsageData(
            currentTokens: 1000,
            maxTokens: 15_000_000,
            timeRemaining: 9000, // 2.5 hours in seconds
            models: [],
            costUSD: 0,
            lastUpdated: Date()
        )
        XCTAssertEqual(usageData.timeRemainingFormatted, "2h 30m")
    }

    func testEmptyUsageData() {
        let usageData = UsageData.empty
        XCTAssertEqual(usageData.currentTokens, 0)
        XCTAssertEqual(usageData.maxTokens, 0)
        XCTAssertEqual(usageData.usageLevel, .normal)
    }

    // Helper function
    private func createUsageData(currentTokens: Int, maxTokens: Int) -> UsageData {
        UsageData(
            currentTokens: currentTokens,
            maxTokens: maxTokens,
            timeRemaining: 3600,
            models: ["claude-sonnet-4-20250514"],
            costUSD: 5.0,
            lastUpdated: Date()
        )
    }
}
