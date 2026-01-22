import Foundation

/// Represents a single line from Claude Code's JSONL log files
struct LogEntry: Codable {
    let type: String
    let timestamp: String?
    let sessionId: String?
    let message: Message?
    let uuid: String?

    struct Message: Codable {
        let role: String?
        let model: String?
        let usage: Usage?
    }

    struct Usage: Codable {
        let inputTokens: Int
        let cacheCreationInputTokens: Int
        let cacheReadInputTokens: Int
        let outputTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case cacheCreationInputTokens = "cache_creation_input_tokens"
            case cacheReadInputTokens = "cache_read_input_tokens"
            case outputTokens = "output_tokens"
        }

        /// Calculate total token count for 44k limit
        var weightedTotal: Double {
            return Double(inputTokens + outputTokens)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
        case timestamp
        case sessionId
        case message
        case uuid
    }

    /// Parse ISO 8601 timestamp string to Date
    var date: Date? {
        guard let timestamp = timestamp else { return nil }

        let formatter = ISO8601DateFormatter()

        // Try with fractional seconds first (Claude Code format)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: timestamp) {
            return date
        }

        // Fall back to without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: timestamp)
    }

    /// Check if this entry is an assistant message with usage data
    var isAssistantWithUsage: Bool {
        return type == "assistant" && message?.usage != nil
    }

    /// Get the model multiplier for rate limit calculation
    /// Opus costs more against the rate limit than Sonnet
    var modelMultiplier: Double {
        guard let model = message?.model?.lowercased() else { return 1.0 }
        if model.contains("opus") {
            return 2.25  // Opus tokens count ~2.25x against the limit
        }
        return 1.0  // Sonnet and others at base rate
    }

    /// Calculate weighted tokens for this entry (accounting for model cost)
    var weightedTokens: Double {
        guard let usage = message?.usage else { return 0 }
        return Double(usage.inputTokens + usage.outputTokens) * modelMultiplier
    }
}
