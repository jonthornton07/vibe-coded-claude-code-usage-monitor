import Foundation

/// Service that wraps ccusage CLI to get accurate usage data
class CCUsageService {
    
    /// Response from ccusage blocks --active --json
    struct BlocksResponse: Codable {
        let blocks: [Block]
    }
    
    struct Block: Codable {
        let id: String
        let startTime: String
        let endTime: String
        let actualEndTime: String?
        let isActive: Bool
        let isGap: Bool
        let entries: Int
        let tokenCounts: TokenCounts
        let totalTokens: Int
        let costUSD: Double
        let models: [String]
        let burnRate: BurnRate?
        let projection: Projection?
    }
    
    struct TokenCounts: Codable {
        let inputTokens: Int
        let outputTokens: Int
        let cacheCreationInputTokens: Int
        let cacheReadInputTokens: Int
    }
    
    struct BurnRate: Codable {
        let tokensPerMinute: Double
        let tokensPerMinuteForIndicator: Double
        let costPerHour: Double
    }
    
    struct Projection: Codable {
        let totalTokens: Int
        let totalCost: Double
        let remainingMinutes: Int
    }
    
    /// Cached max tokens from previous sessions
    private var cachedMaxTokens: Int?
    
    /// Check if ccusage is available
    func isAvailable() -> Bool {
        let result = shell("npx ccusage --version 2>/dev/null")
        return !result.isEmpty
    }
    
    /// Get the active block data from ccusage
    func getActiveBlock() -> Block? {
        let output = shell("npx ccusage blocks --active --json 2>/dev/null")
        guard !output.isEmpty else { return nil }
        
        do {
            let data = output.data(using: .utf8)!
            let response = try JSONDecoder().decode(BlocksResponse.self, from: data)
            return response.blocks.first { $0.isActive }
        } catch {
            print("Error parsing ccusage output: \(error)")
            return nil
        }
    }
    
    /// Get all blocks from ccusage (for finding max historical tokens)
    func getAllBlocks() -> [Block] {
        let output = shell("npx ccusage blocks --json 2>/dev/null")
        guard !output.isEmpty else { return [] }
        
        do {
            let data = output.data(using: .utf8)!
            let response = try JSONDecoder().decode(BlocksResponse.self, from: data)
            return response.blocks.filter { !$0.isGap }
        } catch {
            print("Error parsing ccusage blocks: \(error)")
            return []
        }
    }
    
    /// Get the max tokens from historical sessions (for percentage calculation)
    func getMaxHistoricalTokens() -> Int {
        if let cached = cachedMaxTokens {
            return cached
        }
        
        let blocks = getAllBlocks()
        let maxTokens = blocks.map { $0.totalTokens }.max() ?? 0
        
        if maxTokens > 0 {
            cachedMaxTokens = maxTokens
            print("ccusage max historical tokens: \(maxTokens)")
        }
        
        return maxTokens
    }
    
    /// Run a shell command and return the output
    private func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return ""
        }
    }
}
