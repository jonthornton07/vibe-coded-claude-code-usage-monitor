import Foundation

/// Calculates usage data using ccusage CLI
class UsageCalculator {
    private let ccusage = CCUsageService()

    /// Calculate current usage data using ccusage
    func calculateUsage() -> UsageData {
        // Check if ccusage is available
        guard ccusage.isAvailable() else {
            print("Warning: ccusage not available. Install with: npm install -g ccusage")
            return UsageData.empty
        }
        
        // Get active block from ccusage
        guard let activeBlock = ccusage.getActiveBlock() else {
            print("No active block found")
            return UsageData.empty
        }
        
        // Get max historical tokens for percentage calculation
        let maxTokens = ccusage.getMaxHistoricalTokens()
        
        // Calculate time remaining
        let timeRemaining: TimeInterval
        if let projection = activeBlock.projection {
            timeRemaining = TimeInterval(projection.remainingMinutes * 60)
        } else {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let endTime = formatter.date(from: activeBlock.endTime) {
                timeRemaining = max(0, endTime.timeIntervalSince(Date()))
            } else {
                timeRemaining = 0
            }
        }
        
        // Calculate percentage
        let percentage = maxTokens > 0 ? Double(activeBlock.totalTokens) / Double(maxTokens) * 100.0 : 0.0
        
        // Debug output
        print("ccusage: \(activeBlock.totalTokens) / \(maxTokens) tokens (\(String(format: "%.1f", percentage))%) - resets in \(Int(timeRemaining / 60))m")
        
        return UsageData(
            currentTokens: activeBlock.totalTokens,
            maxTokens: maxTokens,
            timeRemaining: timeRemaining,
            models: activeBlock.models,
            costUSD: activeBlock.costUSD,
            lastUpdated: Date()
        )
    }
}
