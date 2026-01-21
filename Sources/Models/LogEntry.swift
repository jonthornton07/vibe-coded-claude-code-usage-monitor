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
        /// Note: input_tokens already accounts for cache behavior, don't double-count
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
}
