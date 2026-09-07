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

    /// Name used by the "span started before BugsnagPerformance.start()" mode.
    /// Fixed rather than derived from `spanName` because the span is created
    /// before `variant_name` is meaningful for this path.
    static let earlySpanName = "DiskIOPSScenarioEarlySpan"

    /// Raw values of `BSGDiskIOSnapshotFaultMode` (see `BSGDiskIOCollector.h`).
    /// The enum is not exposed to Swift, so the raw bitmask is used.
    /// Retained per PLAT-17203 (Option A) - used by the negative-delta
    /// omission scenario, which cannot be driven from a real device otherwise.
    private static let faultModeNone: UInt = 0
    private static let faultModeFailAtStart: UInt = 1 << 0
    private static let faultModeFailAtEnd: UInt = 1 << 1
    private static let faultModeZeroDuration: UInt = 1 << 2
    private static let faultModeNegativeDelta: UInt = 1 << 3

    /// Span opened before Bugsnag was started (see `start_before_bugsnag_start`).
    private var earlySpan: BugsnagPerformanceSpan?

    /// Started-never-ended spans for the orphan-smoke mode. Strong references
    /// keep them alive (and open) for the lifetime of the scenario.
    private var orphanSpans: [BugsnagPerformanceSpan] = []

    /// Span driven across an app lifecycle transition.
    private var lifecycleSpan: BugsnagPerformanceSpan?
    private var lifecycleSpanEnded = false

    /// Pre-created file for read-only / file-copy workloads. Written (and
    /// flushed) BEFORE the measured span starts so in-span reads are real.
    private var readTargetURL: URL?

    override func startBugsnag() {
        applyFaultMode()
        // Opening the span here keeps it strictly before `BugsnagPerformance.start()`.
        // Disk sampling is gated behind `isStarted_`, so no start snapshot can be
        // captured — this drives the real "start snapshot unavailable" path.
        if toBool(string: scenarioConfig["start_before_bugsnag_start"]) {
            let opts = BugsnagPerformanceSpanOptions()
            opts.setFirstClass(.yes)
            opts.setMakeCurrentContext(false)
            earlySpan = BugsnagPerformance.startSpan(name: DiskIOPSScenario.earlySpanName, options: opts)
        }
        // The orphan-smoke mode delivers 100 completed spans; batch them into a
        // single trace request instead of 100 separate uploads.
        if toBool(string: scenarioConfig["orphan_mode"]) {
            bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
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
        if let earlySpan = earlySpan {
            runEarlySpanMode(span: earlySpan)
            return
        }
        if toBool(string: scenarioConfig["concurrent"]) {
            runConcurrentMode()
            return
        }
        if toBool(string: scenarioConfig["orphan_mode"]) {
            runOrphanMode()
            return
        }
        switch scenarioConfig["lifecycle_mode"] {
        case "mid_span_background":
            runMidSpanBackgroundMode()
            return
        case "start_in_background":
            runStartInBackgroundMode()
            return
        default:
            break
        }
        runSingleSpanMode()
    }

    // MARK: - Modes

    private func runSingleSpanMode() {
        prepareWorkload()

        let span: BugsnagPerformanceSpan
        if scenarioConfig["span_type"] == "app_session" {
            // Real app-session API: SDK controls the "[AppSession/<type>]" name
            // and category. App-session spans are first class, so they are
            // disk-eligible under the default tri-state rules.
            span = BugsnagPerformance.startAppSessionSpan("DiskIOPS")
        } else {
            let opts = BugsnagPerformanceSpanOptions()
            opts.setFirstClass(toTriState(string: scenarioConfig["opts_first_class"]))
            opts.metricsOptions.disk = toTriState(string: scenarioConfig["opts_metrics_disk"])
            span = BugsnagPerformance.startSpan(name: spanName, options: opts)
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

    /// Ends a span that was started before `BugsnagPerformance.start()`.
    /// The collector holds no start snapshot for it, so the end path must omit
    /// all disk attributes while still exporting the span intact.
    private func runEarlySpanMode(span: BugsnagPerformanceSpan) {
        doConfiguredDiskWork()
        let spanDuration = toDouble(string: scenarioConfig["span_duration"])
        DispatchQueue.main.asyncAfter(deadline: .now() + spanDuration) {
            span.end()
            self.earlySpan = nil
            self.flushAfterDelay()
        }
    }

    /// Two overlapping spans with B nested inside A (A: T0→T3, B: T1→T2).
    /// All forced I/O happens in the A-only windows, outside B's lifetime, so
    /// A's counters must differ from B's — a shared or leaked snapshot would
    /// make them identical.
    private func runConcurrentMode() {
        let spanA = BugsnagPerformance.startSpan(name: spanName + "A", options: concurrentSpanOptions()) // T0
        forcedWrite(bytes: 2_097_152)

        let spanB = BugsnagPerformance.startSpan(name: spanName + "B", options: concurrentSpanOptions()) // T1
        // B's window is deliberately idle: no forced I/O until B has ended.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            spanB.end() // T2
            self.forcedWrite(bytes: 2_097_152)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                spanA.end() // T3
                self.flushAfterDelay()
            }
        }
    }

    /// 50 spans that start but never end, alongside 100 spans that complete
    /// normally. All 100 completed spans must deliver valid disk attributes
    /// and the app must not crash or exhaust memory.
    private func runOrphanMode() {
        let opts = BugsnagPerformanceSpanOptions()
        opts.setFirstClass(.yes)
        opts.setMakeCurrentContext(false)

        for _ in 0..<50 {
            orphanSpans.append(BugsnagPerformance.startSpan(name: spanName + "Orphan", options: opts))
        }

        forcedWrite(bytes: 1_048_576)

        for _ in 0..<100 {
            let span = BugsnagPerformance.startSpan(name: spanName, options: opts)
            // Guarantee a strictly positive wall-clock duration per span.
            usleep(2000)
            span.end()
        }
        flushAfterDelay()
    }

    /// An app-session span held open across background → foreground. Session
    /// spans are the only span type the SDK keeps open across backgrounding
    /// (all other open spans are deliberately aborted), so they are the only
    /// honest vehicle for the "mid-span transition" lifecycle row.
    private func runMidSpanBackgroundMode() {
        lifecycleSpan = BugsnagPerformance.startAppSessionSpan("DiskIOPS")
        forcedWrite(bytes: 1_048_576)
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                               object: nil, queue: nil) { _ in
            self.endLifecycleSpanOnce()
        }
        // Maze Runner drives the actual transition via
        // "I switch to the web browser for N seconds".
    }

    /// A first-class span started while the app is in the background and ended
    /// after returning to the foreground.
    private func runStartInBackgroundMode() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                               object: nil, queue: nil) { _ in
            guard self.lifecycleSpan == nil else { return }
            let opts = BugsnagPerformanceSpanOptions()
            opts.setFirstClass(.yes)
            opts.setMakeCurrentContext(false)
            self.lifecycleSpan = BugsnagPerformance.startSpan(name: self.spanName, options: opts)
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

    private func endLifecycleSpanOnce() {
        guard let span = lifecycleSpan, !lifecycleSpanEnded else { return }
        lifecycleSpanEnded = true
        // Small settle delay after foregrounding before ending the span.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            span.end()
            self.flushAfterDelay()
        }
    }

    private func concurrentSpanOptions() -> BugsnagPerformanceSpanOptions {
        let opts = BugsnagPerformanceSpanOptions()
        opts.setFirstClass(toTriState(string: scenarioConfig["opts_first_class"]))
        opts.metricsOptions.disk = toTriState(string: scenarioConfig["opts_metrics_disk"])
        opts.setMakeCurrentContext(false)
        return opts
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

    /// Pre-span setup: read-style workloads need an on-disk source file that
    /// was written (and flushed out of the page cache) before the span starts.
    private func prepareWorkload() {
        switch scenarioConfig["workload"] {
        case "read", "file_copy":
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
        case "read":
            if let url = readTargetURL { forcedRead(url: url) }
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

    /// Reads the whole file through F_NOCACHE so the reads hit the disk rather
    /// than the page cache.
    private func forcedRead(url: URL) {
        let fd = open(url.path, O_RDONLY)
        guard fd >= 0 else {
            logError("DiskIOPSScenario: forcedRead open failed: \(String(cString: strerror(errno)))")
            return
        }
        defer { close(fd) }
        _ = fcntl(fd, F_NOCACHE, 1)
        var buffer = [UInt8](repeating: 0, count: 262_144)
        while true {
            let count = buffer.withUnsafeMutableBytes { raw -> Int in
                read(fd, raw.baseAddress, raw.count)
            }
            if count <= 0 { break }
        }
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

    /// Maps the `disk_fault_mode` scenario config onto the internal test-only
    /// fault mask. Must run before `BugsnagPerformance.start()`.
    private func applyFaultMode() {
        let mode = scenarioConfig["disk_fault_mode"] ?? "none"
        let mask: UInt
        switch mode {
        case "none":
            mask = DiskIOPSScenario.faultModeNone
        case "fail_start":
            mask = DiskIOPSScenario.faultModeFailAtStart
        case "fail_end":
            mask = DiskIOPSScenario.faultModeFailAtEnd
        case "zero_duration":
            mask = DiskIOPSScenario.faultModeZeroDuration
        case "negative_delta":
            mask = DiskIOPSScenario.faultModeNegativeDelta
        default:
            fatalError("\(mode): Unknown disk_fault_mode")
        }
        bugsnagPerfConfig.internal.diskIOSnapshotFaultMode = mask
        logDebug("DiskIOPSScenario: diskIOSnapshotFaultMode = \(mask)")
    }

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
