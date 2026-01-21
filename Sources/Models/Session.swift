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
        let now = Date()
        let elapsed = now.timeIntervalSince(startTime)
        return elapsed < Self.sessionDuration
    }

    /// Time remaining in session
    var timeRemaining: TimeInterval {
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = Self.sessionDuration - elapsed
        return max(0, remaining)
    }

    /// Calculate total weighted tokens used in this session
    var totalTokens: Double {
        entries
            .compactMap { $0.message?.usage }
            .reduce(0.0) { $0 + $1.weightedTotal }
    }

    /// Percentage of 44,000 token limit used
    var usagePercentage: Double {
        (totalTokens / 44000.0) * 100.0
    }

    /// Tokens remaining until limit
    var tokensRemaining: Double {
        max(0, 44000.0 - totalTokens)
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
}
