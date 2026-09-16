//
//  DiskIOPSScenario.swift
//  Fixture
//
//  Created by gaurav agarawal on 03/08/26.
//

import BugsnagPerformance
import SQLite3
import UIKit

@objcMembers
class DiskIOPSScenario: Scenario {

    /// Span driven across an app lifecycle transition.
    private var lifecycleSpan: BugsnagPerformanceSpan?
    private var lifecycleSpanEnded = false

    /// Pre-created file for the file-copy workload. Written (and flushed)
    /// BEFORE the measured span starts so in-span reads are real.
    private var readTargetURL: URL?

    override func startBugsnag() {
        // Test-only: attach the raw snapshot byte counters as
        // bugsnag.internal.disk_io.* attributes so the feature file can assert
        // snapshot freshness. Must be set before BugsnagPerformance.start().
        if toBool(string: scenarioConfig["attach_disk_snapshots"]) {
            bugsnagPerfConfig.internal.attachDiskIOSnapshots = true
        }
        // The sequential mode delivers its two spans in ONE batch.
        if toBool(string: scenarioConfig["sequential_mode"]) {
            bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 2
        }
        // The mixed mode delivers its disk-on and disk-off spans in ONE batch
        if toBool(string: scenarioConfig["mixed_mode"]) {
            bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 2
        }
        super.startBugsnag()
    }

    override func run() {
        let runDelay = toDouble(string: scenarioConfig["run_delay"])
        if runDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + runDelay) {
                self.delayedRun()
            }
        } else {
            // Run synchronously when delay is 0 so there is no timing gap.
            delayedRun()
        }
    }

    func delayedRun() {
        if toBool(string: scenarioConfig["sequential_mode"]) {
            runSequentialMode()
            return
        }
        if toBool(string: scenarioConfig["mixed_mode"]) {
            runMixedMode()
            return
        }
        switch scenarioConfig["lifecycle_mode"] {
        case "mid_span_background":
            runMidSpanBackgroundMode()
            return
        case "start_in_background":
            runStartInBackgroundMode()
            return
        case "start_end_in_background":
            runStartEndInBackgroundMode()
            return
        default:
            break
        }
        runSingleSpanMode()
    }

    // MARK: - Modes

    /// Custom span name from the QA doc (e.g. "DiskIopsWorkload",
    /// "DiskIopsCustom", "DiskIopsIsolation"). Falls back to the
    /// variant-derived name.
    private var configuredSpanName: String {
        if let name = scenarioConfig["span_name"], !name.isEmpty {
            return name
        }
        return spanName
    }

    private func runSingleSpanMode() {
        prepareWorkload()

        let span: BugsnagPerformanceSpan
        if scenarioConfig["span_type"] == "app_session" {
            // Real app-session API: SDK controls the "[AppSession/<type>]" name
            // and category. App-session spans are first class, so they are
            // disk-eligible under the default tri-state rules. `span_name` is
            // ignored on this path by design.
            // Session type "DiskIops" gives the span name "[AppSession/DiskIops]",
            span = BugsnagPerformance.startAppSessionSpan("DiskIops")
        } else {
            let opts = BugsnagPerformanceSpanOptions()
            opts.setFirstClass(toTriState(string: scenarioConfig["opts_first_class"]))
            opts.metricsOptions.disk = toTriState(string: scenarioConfig["opts_metrics_disk"])
            span = BugsnagPerformance.startSpan(name: configuredSpanName, options: opts)
        }

        performWorkload()

        let spanDuration = toDouble(string: scenarioConfig["span_duration"])

        // End span + wait for batch flush to guarantee Maze Runner receives
        // the trace before the 30s step timeout.
        DispatchQueue.main.asyncAfter(deadline: .now() + spanDuration) {
            span.end()
            self.flushAfterDelay()
        }
    }

    /// Two back-to-back spans: the second starts only after the first has
    /// ended, each doing forced I/O in its own window. Each span must capture
    /// a fresh start snapshot rather than reusing the previous span's
    /// counters, so each span is asserted independently in the feature file.
    private func runSequentialMode() {
        let span1 = BugsnagPerformance.startSpan(name: "DiskIopsSequential1", options: sequentialSpanOptions())
        forcedWrite(bytes: 1_048_576)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            span1.end()
            let span2 = BugsnagPerformance.startSpan(name: "DiskIopsSequential2", options: self.sequentialSpanOptions())
            self.forcedWrite(bytes: 1_048_576)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                span2.end()
                self.flushAfterDelay()
            }
        }
    }

    private func sequentialSpanOptions() -> BugsnagPerformanceSpanOptions {
        let opts = BugsnagPerformanceSpanOptions()
        opts.setFirstClass(.yes)
        opts.setMakeCurrentContext(false)
        return opts
    }

    /// One disk-reporting span ("DiskIopsNewSdk", metricsOptions.disk = yes)
    /// and one disk-omitting span ("DiskIopsOldSdk", metricsOptions.disk = no)
    /// delivered in the same batch - ROAD 2233 Scenario 14 in its SDK-scoped
    private func runMixedMode() {
        let onOpts = BugsnagPerformanceSpanOptions()
        onOpts.setFirstClass(.yes)
        onOpts.metricsOptions.disk = .yes
        onOpts.setMakeCurrentContext(false)
        let newSdkSpan = BugsnagPerformance.startSpan(name: "DiskIopsNewSdk", options: onOpts)

        let offOpts = BugsnagPerformanceSpanOptions()
        offOpts.setFirstClass(.yes)
        offOpts.metricsOptions.disk = .no
        offOpts.setMakeCurrentContext(false)
        let oldSdkSpan = BugsnagPerformance.startSpan(name: "DiskIopsOldSdk", options: offOpts)

        forcedWrite(bytes: 524_288)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            newSdkSpan.end()
            oldSdkSpan.end()
            self.flushAfterDelay()
        }
    }

    /// An app-session span held open across background → foreground. Session
    /// spans are the only span type the SDK keeps open across backgrounding
    /// (all other open spans are deliberately aborted), so they are the only
    /// honest vehicle for the "mid-span transition" lifecycle row.
    private func runMidSpanBackgroundMode() {
        lifecycleSpan = BugsnagPerformance.startAppSessionSpan("DiskIops")
        forcedWrite(bytes: 1_048_576)
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                               object: nil, queue: nil) { _ in
            self.endLifecycleSpanOnce()
        }
        // Maze Runner drives the actual transition via
        // "I switch to the web browser for N seconds".
    }

    /// Span factory for the lifecycle background modes: an app-session span
    /// when `span_type` is "app_session" (the SDK controls the
    /// "[AppSession/DiskIops]" name), otherwise a first-class custom span.
    private func makeLifecycleSpan() -> BugsnagPerformanceSpan {
        if scenarioConfig["span_type"] == "app_session" {
            return BugsnagPerformance.startAppSessionSpan("DiskIops")
        }
        let opts = BugsnagPerformanceSpanOptions()
        opts.setFirstClass(.yes)
        opts.setMakeCurrentContext(false)
        return BugsnagPerformance.startSpan(name: configuredSpanName, options: opts)
    }

    /// A disk-eligible span (custom or app-session, per `span_type`) started
    /// while the app is in the background and ended after returning to the
    /// foreground.
    private func runStartInBackgroundMode() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                               object: nil, queue: nil) { _ in
            guard self.lifecycleSpan == nil else { return }
            self.lifecycleSpan = self.makeLifecycleSpan()
            self.forcedWrite(bytes: 262_144)
            // Keep the process alive briefly so the span start is fully
            // processed before the OS suspends the app (same pattern as
            // BackgroundForegroundScenario).
            Thread.sleep(forTimeInterval: 1)
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                               object: nil, queue: nil) { _ in
            self.endLifecycleSpanOnce()
        }
    }

    /// A disk-eligible span (custom or app-session, per `span_type`) whose
    /// whole lifetime is inside the background window (started and ended
    /// after didEnterBackground). This is the QA doc's "span ends while in
    /// background" row in its achievable form: a span that is merely OPEN
    /// when the app backgrounds is aborted by the SDK by design
    /// (abortOpenSpansOnBackground), so start and end must both happen in the
    /// background for the span to be deliverable - the pattern proven by
    /// BackgroundForegroundScenario.
    private func runStartEndInBackgroundMode() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                               object: nil, queue: nil) { _ in
            guard self.lifecycleSpan == nil else { return }
            let span = self.makeLifecycleSpan()
            self.lifecycleSpan = span
            self.forcedWrite(bytes: 262_144)
            Thread.sleep(forTimeInterval: 0.5)
            span.end()
            self.lifecycleSpanEnded = true
            self.flushAfterDelay()
            // Keep the process alive so the batch can upload before suspension.
            Thread.sleep(forTimeInterval: 2)
        }
    }

    private func endLifecycleSpanOnce() {
        guard let span = lifecycleSpan, !lifecycleSpanEnded else { return }
        lifecycleSpanEnded = true
        // Small settle delay after foregrounding before ending the span.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            span.end()
            self.flushAfterDelay()
        }
    }

    // MARK: - Workloads
    //
    // Forced I/O uses F_NOCACHE plus fsync so bytes genuinely reach the disk
    // and the process-wide counters advance; plain buffered writes/reads can be
    // absorbed entirely by the page cache, which would make any "> 0"
    // assertion in the feature file a lie.

    private var workloadBytes: Int {
        let configured = Int(toDouble(string: scenarioConfig["workload_bytes"]))
        return configured > 0 ? configured : 4_194_304
    }

    /// Pre-span setup: the file-copy workload needs an on-disk source file
    /// that was written (and flushed out of the page cache) before the span
    /// starts.
    private func prepareWorkload() {
        switch scenarioConfig["workload"] {
        case "file_copy":
            readTargetURL = forcedWrite(bytes: workloadBytes)
        default:
            break
        }
    }

    /// In-span workload execution.
    private func performWorkload() {
        switch scenarioConfig["workload"] {
        case "write", "burst_write":
            forcedWrite(bytes: workloadBytes)
        case "sqlite":
            runSQLiteWorkload(insertCount: 1000)
        case "file_copy":
            if let url = readTargetURL { forcedCopy(from: url) }
        default:
            // Legacy path used by the configuration/eligibility scenarios.
            doConfiguredDiskWork()
        }
    }

    /// Writes `bytes` of random data through F_NOCACHE and fsyncs.
    /// Random data defeats any transparent compression; fsync guarantees the
    /// write reaches disk before returning.
    @discardableResult
    private func forcedWrite(bytes: Int, to destination: URL? = nil) -> URL? {
        let url = destination ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("bsg-disk-iops-\(UUID().uuidString).bin")
        let fd = open(url.path, O_CREAT | O_WRONLY | O_TRUNC, 0o644)
        guard fd >= 0 else {
            logError("DiskIOPSScenario: forcedWrite open failed: \(String(cString: strerror(errno)))")
            return nil
        }
        defer { close(fd) }
        _ = fcntl(fd, F_NOCACHE, 1)

        let chunkSize = 262_144
        var chunk = [UInt8](repeating: 0, count: chunkSize)
        var remaining = bytes
        while remaining > 0 {
            arc4random_buf(&chunk, chunkSize)
            let want = min(remaining, chunkSize)
            var offset = 0
            while offset < want {
                let written = chunk.withUnsafeBytes { raw -> Int in
                    write(fd, raw.baseAddress!.advanced(by: offset), want - offset)
                }
                if written <= 0 {
                    logError("DiskIOPSScenario: forcedWrite write failed: \(String(cString: strerror(errno)))")
                    return url
                }
                offset += written
            }
            remaining -= want
        }
        fsync(fd)
        return url
    }

    /// Streams `source` to a new file, both sides through F_NOCACHE, so read
    /// and write counters both advance.
    private func forcedCopy(from source: URL) {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("bsg-disk-iops-copy-\(UUID().uuidString).bin")
        let inFD = open(source.path, O_RDONLY)
        let outFD = open(destination.path, O_CREAT | O_WRONLY | O_TRUNC, 0o644)
        guard inFD >= 0, outFD >= 0 else {
            if inFD >= 0 { close(inFD) }
            if outFD >= 0 { close(outFD) }
            logError("DiskIOPSScenario: forcedCopy open failed")
            return
        }
        defer { close(inFD); close(outFD) }
        _ = fcntl(inFD, F_NOCACHE, 1)
        _ = fcntl(outFD, F_NOCACHE, 1)

        var buffer = [UInt8](repeating: 0, count: 262_144)
        while true {
            let count = buffer.withUnsafeMutableBytes { raw -> Int in
                read(inFD, raw.baseAddress, raw.count)
            }
            if count <= 0 { break }
            var offset = 0
            while offset < count {
                let written = buffer.withUnsafeBytes { raw -> Int in
                    write(outFD, raw.baseAddress!.advanced(by: offset), count - offset)
                }
                if written <= 0 { return }
                offset += written
            }
        }
        fsync(outFD)
        try? FileManager.default.removeItem(at: destination)
    }

    /// Intensive SQLite workload: each INSERT runs in its own implicit
    /// transaction, forcing a journal write + fsync per statement.
    private func runSQLiteWorkload(insertCount: Int) {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("bsg-disk-iops-\(UUID().uuidString).sqlite").path
        var db: OpaquePointer?
        guard sqlite3_open(path, &db) == SQLITE_OK else {
            logError("DiskIOPSScenario: sqlite3_open failed")
            return
        }
        defer {
            sqlite3_close(db)
            try? FileManager.default.removeItem(atPath: path)
        }
        sqlite3_exec(db, "CREATE TABLE t (id INTEGER PRIMARY KEY AUTOINCREMENT, payload BLOB)", nil, nil, nil)
        for i in 0..<insertCount {
            sqlite3_exec(db, "INSERT INTO t (payload) VALUES (randomblob(4096))", nil, nil, nil)
            if i % 100 == 0 {
                sqlite3_exec(db, "SELECT count(*), sum(length(payload)) FROM t", nil, nil, nil)
            }
        }
    }

    // MARK: - Helpers

    private func doConfiguredDiskWork() {
        let workBytes = Int(toDouble(string: scenarioConfig["disk_work_bytes"]))
        if workBytes > 0 {
            doDiskWork(bytes: workBytes)
        }
    }

    private func flushAfterDelay() {
        // Give the SDK time to package and upload the batch.
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            self.waitForCurrentBatch()
        }
    }

    func doDiskWork(bytes: Int) {
        let payload = Data(count: bytes)
        let dir = FileManager.default.temporaryDirectory
        let path = dir.appendingPathComponent("bsg-disk-iops-\(UUID().uuidString).bin")
        do {
            try payload.write(to: path, options: [.atomic])
            _ = try? Data(contentsOf: path)
            try? FileManager.default.removeItem(at: path)
        } catch {
            logError("DiskIOPSScenario: disk work failed: \(error)")
        }
    }
}
