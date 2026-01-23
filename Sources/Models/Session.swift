import Foundation

/// Represents a 5-hour Claude Code usage session
struct Session {
    let sessionId: String
    let startTime: Date
    let entries: [LogEntry]

    /// Session duration: 5 hours
    static let sessionDuration: TimeInterval = 5 * 60 * 60 // 5 hours in seconds

    /// Check if session is still active (within 5 hours)
    var isActive: Bool {
        let cutoff = Date().addingTimeInterval(-Self.sessionDuration)
        return entries.contains { entry in
            guard let d = entry.date else { return false }
            return d >= cutoff
        }
    }

    /// Time remaining in session
    var timeRemaining: TimeInterval {
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = Self.sessionDuration - elapsed
        return max(0, remaining)
    }

    /// Calculate total weighted tokens used in this session
    /// Accounts for model-specific multipliers (Opus costs more)
    var totalTokens: Double {
        let cutoff = Date().addingTimeInterval(-Self.sessionDuration)
        return entries.reduce(0.0) { acc, entry in
            guard let d = entry.date, d >= cutoff else { return acc }
            return acc + entry.weightedTokens
        }
    }

    /// Total tokens including cache (for percentage calculation like ccusage)
    /// Only counts entries within the current 5-hour window
    var totalTokensWithCache: Double {
        let cutoff = Date().addingTimeInterval(-Self.sessionDuration)
        return entries.reduce(0.0) { acc, entry in
            guard let d = entry.date, d >= cutoff else { return acc }
            return acc + entry.totalTokensWithCache
        }
    }

    /// Percentage of token limit used (using cache tokens like ccusage)
    var usagePercentage: Double {
        (totalTokensWithCache / Config.quotaTokens()) * 100.0
    }

    /// Tokens remaining until limit
    var tokensRemaining: Double {
        max(0, Config.quotaTokens() - totalTokens)
    }

    /// Format time remaining as "Xh Ym"
    var timeRemainingFormatted: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    /// Format start time as "HH:MM AM/PM"
    var startTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }

    /// Get the primary model used in this session (most recent)
    var modelName: String {
        guard let model = entries.last?.message?.model else { return "Unknown" }
        if model.contains("opus") {
            return "Opus"
        } else if model.contains("sonnet") {
            return "Sonnet"
        } else if model.contains("haiku") {
            return "Haiku"
        }
        return model
    }
}
