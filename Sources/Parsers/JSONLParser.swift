import Foundation

/// Parser for Claude Code's JSONL log files
class JSONLParser {
    private let decoder = JSONDecoder()

    /// Parse a JSONL file and return all log entries
    /// - Parameter fileURL: URL to the .jsonl file
    /// - Returns: Array of LogEntry objects
    func parse(fileURL: URL) throws -> [LogEntry] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return try parse(content: content)
    }

    /// Parse JSONL content string
    /// - Parameter content: JSONL file content as string
    /// - Returns: Array of LogEntry objects
    func parse(content: String) throws -> [LogEntry] {
        let lines = content.components(separatedBy: .newlines)
        var entries: [LogEntry] = []

        for (lineNumber, line) in lines.enumerated() {
            // Skip empty lines
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else {
                continue
            }

            guard let data = line.data(using: .utf8) else {
                print("Warning: Could not encode line \(lineNumber + 1) to UTF-8")
                continue
            }

            do {
                let entry = try decoder.decode(LogEntry.self, from: data)
                entries.append(entry)
            } catch {
                // Log parsing errors but continue processing
                print("Warning: Could not parse line \(lineNumber + 1): \(error)")
                continue
            }
        }

        return entries
    }

    /// Parse all JSONL files in a directory
    /// - Parameter directoryURL: URL to directory containing .jsonl files
    /// - Returns: Dictionary mapping file URLs to their log entries
    func parseDirectory(directoryURL: URL) throws -> [URL: [LogEntry]] {
        let fileManager = FileManager.default
        var results: [URL: [LogEntry]] = [:]

        // Get all .jsonl files in directory
        let contents = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        let jsonlFiles = contents.filter { $0.pathExtension == "jsonl" }

        for fileURL in jsonlFiles {
            do {
                let entries = try parse(fileURL: fileURL)
                results[fileURL] = entries
            } catch {
                print("Error parsing \(fileURL.lastPathComponent): \(error)")
                continue
            }
        }

        return results
    }

    /// Find all Claude Code project directories
    /// - Returns: Array of project directory URLs
    static func findProjectDirectories() -> [URL] {
        let fileManager = FileManager.default
        let claudeProjectsPath = Config.claudeProjectsPath()

        guard fileManager.fileExists(atPath: claudeProjectsPath.path) else {
            print("Claude projects directory not found at: \(claudeProjectsPath.path)")
            return []
        }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: claudeProjectsPath,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            return contents.filter { url in
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
                return isDirectory.boolValue
            }
        } catch {
            print("Error reading Claude projects directory: \(error)")
            return []
        }
    }
}
