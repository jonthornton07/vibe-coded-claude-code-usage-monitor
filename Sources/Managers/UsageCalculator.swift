import Foundation

/// Calculates aggregated usage data across all active sessions
class UsageCalculator {
    private let sessionManager = SessionManager()
    private let parser = JSONLParser()

    /// Calculate current usage data
    /// - Returns: UsageData object with aggregated information
    func calculateUsage() -> UsageData {
        let activeSessions = sessionManager.loadActiveSessions(using: parser)

        // Debug output
        print("Active sessions: \(activeSessions.count)")
        for session in activeSessions {
            print("  Session \(session.sessionId): \(String(format: "%.0f", session.totalTokens)) tokens, started \(session.startTimeFormatted), \(session.timeRemainingFormatted) remaining")
        }

        let usageData = UsageData(
            activeSessions: activeSessions,
            lastUpdated: Date()
        )
        print("Total usage: \(String(format: "%.0f", usageData.totalTokens)) tokens (\(String(format: "%.1f", usageData.usagePercentage))%)")

        return usageData
    }

    /// Calculate usage from specific sessions
    /// - Parameter sessions: Array of Session objects
    /// - Returns: UsageData object
    func calculateUsage(from sessions: [Session]) -> UsageData {
        let activeSessions = sessions.filter { $0.isActive }
        return UsageData(
            activeSessions: activeSessions,
            lastUpdated: Date()
        )
    }
}
