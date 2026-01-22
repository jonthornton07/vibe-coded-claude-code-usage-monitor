import Cocoa

/// Controls the macOS menu bar status item
class StatusBarController {
    private var statusItem: NSStatusItem?
    private let calculator = UsageCalculator()
    private let fileMonitor = FileMonitor()
    private var currentUsageData: UsageData = .empty
    private var refreshTimer: Timer?

    init() {
        setupStatusItem()
        setupFileMonitoring()
        setupSystemNotifications()
        setupRefreshTimer()
        refreshUsage()
    }

    deinit {
        refreshTimer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "Loading..."
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }

    private func setupFileMonitoring() {
        fileMonitor.onChange = { [weak self] in
            DispatchQueue.main.async {
                self?.refreshUsage()
            }
        }
        fileMonitor.startMonitoring()
    }

    private func setupSystemNotifications() {
        // Listen for system wake events
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Listen for screen unlock events
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleScreenUnlock),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
    }

    private func setupRefreshTimer() {
        // Conservative 60-second backup timer
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: 60.0,
            repeats: true
        ) { [weak self] _ in
            self?.refreshUsage()
        }
    }

    @objc private func handleSystemWake() {
        print("System woke from sleep, refreshing usage...")
        refreshUsage()
    }

    @objc private func handleScreenUnlock() {
        print("Screen unlocked, refreshing usage...")
        refreshUsage()
    }

    @objc private func statusBarButtonClicked() {
        guard statusItem?.button != nil else { return }

        let menu = NSMenu()

        // Section 1: Current Usage
        menu.addItem(createUsageHeaderItem())

        if !currentUsageData.activeSessions.isEmpty {
            menu.addItem(createTokensUsedItem())
            menu.addItem(createPercentageItem())

            // Show session details if there are active sessions
            menu.addItem(NSMenuItem.separator())
            menu.addItem(createSessionsHeaderItem())

            for session in currentUsageData.activeSessions.prefix(5) {
                menu.addItem(createSessionItem(session))
            }
        } else {
            menu.addItem(createNoActiveSessionsItem())
        }

        // Section 2: Actions
        menu.addItem(NSMenuItem.separator())
        menu.addItem(createRefreshItem())

        // Section 3: App
        menu.addItem(NSMenuItem.separator())
        menu.addItem(createAboutItem())
        menu.addItem(createQuitItem())

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    private func createUsageHeaderItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Claude Code Usage", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func createTokensUsedItem() -> NSMenuItem {
        let tokens = String(format: "%.0f", currentUsageData.totalTokens)
        let item = NSMenuItem(title: "  Tokens: \(tokens) / 44,000", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func createPercentageItem() -> NSMenuItem {
        let percentage = String(format: "%.1f%%", currentUsageData.usagePercentage)
        let item = NSMenuItem(title: "  Usage: \(percentage)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func createSessionsHeaderItem() -> NSMenuItem {
        let count = currentUsageData.activeSessions.count
        let item = NSMenuItem(title: "Active Sessions (\(count))", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func createSessionItem(_ session: Session) -> NSMenuItem {
        let tokens = String(format: "%.0fk", session.totalTokens / 1000)
        let percentage = String(format: "%.0f%%", session.usagePercentage)
        let title = "  \(session.modelName): \(tokens) (\(percentage)) - \(session.timeRemainingFormatted) left"
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func createNoActiveSessionsItem() -> NSMenuItem {
        let item = NSMenuItem(title: "  No active sessions", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func createRefreshItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Refresh Usage", action: #selector(refreshUsageClicked), keyEquivalent: "r")
        item.target = self
        return item
    }

    private func createAboutItem() -> NSMenuItem {
        let item = NSMenuItem(title: "About", action: #selector(aboutClicked), keyEquivalent: "")
        item.target = self
        return item
    }

    private func createQuitItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "q")
        item.target = self
        return item
    }

    @objc private func refreshUsageClicked() {
        refreshUsage()
    }

    @objc private func aboutClicked() {
        let alert = NSAlert()
        alert.messageText = "Claude Code Monitor"
        alert.informativeText = "Monitor your Claude Code token usage in real-time.\n\nVersion 1.0\nBuilt with Swift"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }

    func refreshUsage() {
        // Calculate on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let usageData = self?.calculator.calculateUsage() ?? .empty

            // Update UI on main queue
            DispatchQueue.main.async {
                self?.currentUsageData = usageData
                self?.updateStatusBarDisplay()
            }
        }
    }

    private func updateStatusBarDisplay() {
        guard let button = statusItem?.button else { return }

        let text = currentUsageData.statusBarText

        // For normal state, use plain title to allow system transparency/vibrancy
        // For warning/critical, use attributed string with custom color
        switch currentUsageData.usageLevel {
        case .normal:
            // Clear attributed title and use plain title for system transparency
            button.attributedTitle = NSAttributedString(string: "")
            button.title = text
        case .warning, .critical:
            let color: NSColor = currentUsageData.usageLevel == .warning ? .systemOrange : .systemRed
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: color
            ]
            button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
        }
    }
}
