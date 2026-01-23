import Foundation

/// Usage data from ccusage
struct UsageData {
    let currentTokens: Int
    let maxTokens: Int
    let timeRemaining: TimeInterval
    let models: [String]
    let costUSD: Double
    let lastUpdated: Date

    /// Percentage of token limit used
    var usagePercentage: Double {
        guard maxTokens > 0 else { return 0.0 }
        return Double(currentTokens) / Double(maxTokens) * 100.0
    }

    /// Status bar display text
    var statusBarText: String {
        String(format: "%.1f%%", usagePercentage)
    }

    /// Format current tokens as "12.5M" or "1.2M"
    var tokensFormatted: String {
        let m = Double(currentTokens) / 1_000_000.0
        return String(format: "%.1fM", m)
    }

    /// Format max tokens as "14.6M"
    var maxTokensFormatted: String {
        let m = Double(maxTokens) / 1_000_000.0
        return String(format: "%.1fM", m)
    }

    /// Time remaining formatted as "Xh Ym"
    var timeRemainingFormatted: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        return "\(hours)h \(minutes)m"
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

    /// Empty usage data
    static var empty: UsageData {
        UsageData(currentTokens: 0, maxTokens: 0, timeRemaining: 0, models: [], costUSD: 0, lastUpdated: Date())
    }
}
