import Foundation

/// Aggregated usage data across all active sessions
struct UsageData {
    let activeSessions: [Session]
    let lastUpdated: Date

    /// Total tokens across all active sessions
    var totalTokens: Double {
        activeSessions.reduce(0.0) { $0 + $1.totalTokens }
    }

    /// Percentage of 44,000 limit used (summed across sessions)
    var usagePercentage: Double {
        (totalTokens / 44000.0) * 100.0
    }

    /// Tokens remaining until limit
    var tokensRemaining: Double {
        max(0, 44000.0 - totalTokens)
    }

    /// Format total tokens as "12.5k" or "42k"
    var tokensFormatted: String {
        let k = totalTokens / 1000.0
        if k < 10 {
            return String(format: "%.1fk", k)
        } else {
            return String(format: "%.0fk", k)
        }
    }

    /// Status bar display text: "14.6%"
    var statusBarText: String {
        String(format: "%.1f%%", usagePercentage)
    }

    /// Color indicator based on usage percentage
    enum UsageLevel {
        case normal  // < 70%
        case warning // 70-90%
        case critical // > 90%
    }

    var usageLevel: UsageLevel {
        if usagePercentage >= 90 {
            return .critical
        } else if usagePercentage >= 70 {
            return .warning
        } else {
            return .normal
        }
    }

    /// Empty usage data (no active sessions)
    static var empty: UsageData {
        UsageData(activeSessions: [], lastUpdated: Date())
    }
}
