//
//  DiskIOPSScenario.swift
//  Fixture
//
//  Created by gaurav agarawal on 03/08/26.
//

import BugsnagPerformance

@objcMembers
class DiskIOPSScenario: Scenario {

    /// Name used by the "span started before BugsnagPerformance.start()" mode.
    /// Fixed rather than derived from `spanName` because the span is created
    /// before `variant_name` is meaningful for this path.
    static let earlySpanName = "DiskIOPSScenarioEarlySpan"

    /// Raw values of `BSGDiskIOSnapshotFaultMode` (see `BSGDiskIOCollector.h`).
    /// The enum is not exposed to Swift, so the raw bitmask is used.
    private static let faultModeNone: UInt = 0
    private static let faultModeFailAtStart: UInt = 1 << 0
    private static let faultModeFailAtEnd: UInt = 1 << 1
    private static let faultModeZeroDuration: UInt = 1 << 2
    private static let faultModeNegativeDelta: UInt = 1 << 3

    /// Span opened before Bugsnag was started (see `start_before_bugsnag_start`).
    private var earlySpan: BugsnagPerformanceSpan?

    override func startBugsnag() {
        applyFaultMode()
        // Opening the span here keeps it strictly before `BugsnagPerformance.start()`.
        // Disk sampling is gated behind `isStarted_`, so no start snapshot can be
        // captured — this drives the real "start snapshot unavailable" path
        // without any fault injection.
        if toBool(string: scenarioConfig["start_before_bugsnag_start"]) {
            let opts = BugsnagPerformanceSpanOptions()
            opts.setFirstClass(.yes)
            opts.setMakeCurrentContext(false)
            earlySpan = BugsnagPerformance.startSpan(name: DiskIOPSScenario.earlySpanName, options: opts)
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
        runSingleSpanMode()
    }

    // MARK: - Modes

    private func runSingleSpanMode() {
        let opts = BugsnagPerformanceSpanOptions()
        opts.setFirstClass(toTriState(string: scenarioConfig["opts_first_class"]))
        opts.metricsOptions.disk = toTriState(string: scenarioConfig["opts_metrics_disk"])
        let span = BugsnagPerformance.startSpan(name: spanName, options: opts)

        // Produce some disk activity inside the span so the byte counters have a
        // chance to advance. Best-effort - some hosts may still show zero deltas,
        // so assertions must not require strictly > 0 values.
        doConfiguredDiskWork()

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

    /// Two deliberately overlapping spans, each with its own start snapshot.
    /// Neither is the other's parent (`makeCurrentContext = false`) so a snapshot
    /// leak between them would be observable in the exported payload.
    private func runConcurrentMode() {
        let spanA = BugsnagPerformance.startSpan(name: spanName + "A", options: concurrentSpanOptions())
        doConfiguredDiskWork()

        let spanB = BugsnagPerformance.startSpan(name: spanName + "B", options: concurrentSpanOptions())
        doConfiguredDiskWork()

        // Clamp so the overlap window is always observable even if the feature
        // file passes a very small duration.
        let spanDuration = max(toDouble(string: scenarioConfig["span_duration"]), 0.2)

        // A starts first and ends first; B stays open across the remainder,
        // guaranteeing a real overlap window between the two spans.
        DispatchQueue.main.asyncAfter(deadline: .now() + spanDuration) {
            spanA.end()
            self.doConfiguredDiskWork()
            DispatchQueue.main.asyncAfter(deadline: .now() + spanDuration) {
                spanB.end()
                self.flushAfterDelay()
            }
        }
    }

    private func concurrentSpanOptions() -> BugsnagPerformanceSpanOptions {
        let opts = BugsnagPerformanceSpanOptions()
        opts.setFirstClass(toTriState(string: scenarioConfig["opts_first_class"]))
        opts.metricsOptions.disk = toTriState(string: scenarioConfig["opts_metrics_disk"])
        opts.setMakeCurrentContext(false)
        return opts
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
