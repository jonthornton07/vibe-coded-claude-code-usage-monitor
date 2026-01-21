import Foundation

/// Monitors Claude Code log files for changes using FSEvents
class FileMonitor {
    private var eventStream: FSEventStreamRef?
    private let debounceDelay: TimeInterval = 0.5 // 500ms
    private var debounceTimer: Timer?
    private let queue = DispatchQueue(label: "com.claudecodemonitor.filemonitor")

    /// Callback closure called when files change
    var onChange: (() -> Void)?

    /// Start monitoring the Claude Code projects directory
    func startMonitoring() {
        let projectsURL = Config.claudeProjectsPath()
        let projectsPath = projectsURL.path

        guard FileManager.default.fileExists(atPath: projectsPath) else {
            print("Error: Claude projects directory not found at: \(projectsPath)")
            return
        }

        let pathsToWatch = [projectsPath as CFString] as CFArray
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { (
            streamRef,
            clientCallBackInfo,
            numEvents,
            eventPaths,
            eventFlags,
            eventIds
        ) in
            guard let info = clientCallBackInfo else { return }
            let monitor = Unmanaged<FileMonitor>.fromOpaque(info).takeUnretainedValue()
            monitor.handleFileSystemEvent()
        }

        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5, // latency in seconds
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        guard let stream = eventStream else {
            print("Error: Failed to create FSEventStream")
            return
        }

        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)

        print("Started monitoring: \(projectsPath)")
    }

    /// Stop monitoring files
    func stopMonitoring() {
        debounceTimer?.invalidate()
        debounceTimer = nil

        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
            print("Stopped monitoring files")
        }
    }

    /// Handle file system events with debouncing
    private func handleFileSystemEvent() {
        // Cancel existing timer
        debounceTimer?.invalidate()

        // Create new timer
        debounceTimer = Timer.scheduledTimer(
            withTimeInterval: debounceDelay,
            repeats: false
        ) { [weak self] _ in
            self?.triggerOnChange()
        }
    }

    /// Trigger the onChange callback
    private func triggerOnChange() {
        queue.async { [weak self] in
            self?.onChange?()
        }
    }

    deinit {
        stopMonitoring()
    }
}
