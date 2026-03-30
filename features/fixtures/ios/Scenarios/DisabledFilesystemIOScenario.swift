import Foundation
import BugsnagPerformance
import BugsnagPerformanceNamedSpans


@objcMembers
class DisabledFilesystemIOScenario: Scenario {
    var queue: RetryQueueWrapper?
    var filesystemErrorCallCount = 0
    let testFilePath = NSTemporaryDirectory().appending("test-queue-file")

    override func configureBugsnag(path: String, value: String) {
        if path == "disableFilesystemIO" && value == "true" {
            // Will be handled in run()
        } else {
            super.configureBugsnag(path: path, value: value)
        }
    }

    override func run() {
        let fm = FileManager.default
        if fm.fileExists(atPath: testFilePath) {
            try? fm.removeItem(atPath: testFilePath)
        }
        queue = RetryQueueWrapper(path: testFilePath)
        queue?.setOnFilesystemError { [weak self] in self?.filesystemErrorCallCount += 1 }
        queue?.disableFilesystemIO()

        // Now call all queue operations
        queue?.preStartSetup()
        queue?.sweep()
        _ = queue?.list()
        _ = queue?.get(1)
        queue?.remove(1)
    }

    @objc func queuePreStartSetup() {
        queue?.preStartSetup()
    }
    @objc func queueSweep() {
        queue?.sweep()
    }
    @objc func queueList() {
        _ = queue?.list()
    }
    @objc func queueGet() {
        _ = queue?.get(1)
    }
    @objc func queueRemove() {
        queue?.remove(1)
    }
    @objc func get_filesystem_error_call_count() -> Int {
        return filesystemErrorCallCount
    }
    @objc func file_exists_at_queue_path() -> Bool {
        return FileManager.default.fileExists(atPath: testFilePath)
    }
}
