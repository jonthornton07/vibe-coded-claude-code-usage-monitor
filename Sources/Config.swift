import Foundation

/// Application configuration
enum Config {
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
