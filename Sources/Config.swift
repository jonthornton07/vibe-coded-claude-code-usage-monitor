import Foundation

/// Application configuration
enum Config {
    /// Get the Claude Code 5-hour quota in weighted tokens
    /// Defaults to 44,000 if not set via env CLAUDE_QUOTA_TOKENS
    static func quotaTokens() -> Double {
        // Check for learned quota first
        if let learned = UserDefaults.standard.object(forKey: "LearnedSessionQuota") as? Double {
            return learned
        }
        // Then check environment variable
        if let env = ProcessInfo.processInfo.environment["CLAUDE_QUOTA_TOKENS"],
           let val = Double(env) {
            return val
        }
        return 14_632_732.0  // Match ccusage's discovered quota
    }

    /// Save the learned session quota (when user hits 100%)
    static func saveLearnedQuota(_ quota: Double) {
        UserDefaults.standard.set(quota, forKey: "LearnedSessionQuota")
    }

    /// Reset to default quota
    static func resetLearnedQuota() {
        UserDefaults.standard.removeObject(forKey: "LearnedSessionQuota")
    }

    /// Get the model multiplier used to weight tokens against the quota
    /// Defaults: Opus 2.25, Sonnet/Haiku 1.0
    static func modelMultiplier(for modelName: String?) -> Double {
        guard let name = modelName?.lowercased() else { return 1.0 }
        if name.contains("opus") {
            if let env = ProcessInfo.processInfo.environment["CLAUDE_MULTIPLIER_OPUS"],
               let val = Double(env) {
                return val
            }
            return 2.25
        }
        if name.contains("sonnet") {
            if let env = ProcessInfo.processInfo.environment["CLAUDE_MULTIPLIER_SONNET"],
               let val = Double(env) {
                return val
            }
            return 1.0
        }
        if name.contains("haiku") {
            if let env = ProcessInfo.processInfo.environment["CLAUDE_MULTIPLIER_HAIKU"],
               let val = Double(env) {
                return val
            }
            return 1.0
        }
        return 1.0
    }
    /// Get the Claude projects directory path
    /// - Returns: URL to the Claude projects directory
    static func claudeProjectsPath() -> URL {
        let fileManager = FileManager.default

        // Check for environment variable first
        if let envPath = ProcessInfo.processInfo.environment["CLAUDE_PROJECTS_PATH"] {
            let url = URL(fileURLWithPath: (envPath as NSString).expandingTildeInPath)
            if fileManager.fileExists(atPath: url.path) {
                return url
            } else {
                print("Warning: CLAUDE_PROJECTS_PATH set to '\(envPath)' but directory does not exist. Falling back to default.")
            }
        }

        // Fall back to default location
        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
    }
}
