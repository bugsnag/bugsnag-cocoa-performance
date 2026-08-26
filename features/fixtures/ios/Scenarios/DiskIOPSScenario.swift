//
//  DiskIOPSScenario.swift
//  Fixture
//
//  Created by gaurav agarawal on 03/08/26.
//

import BugsnagPerformance

@objcMembers
class DiskIOPSScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        // Pin the sampling probability for this scenario so the span is
        // always delivered, regardless of any P value persisted by a
        // previously-run scenario (same pattern as
        // FixedSamplingProbabilityOneScenario).
        bugsnagPerfConfig.samplingProbability = 1.0
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
        let opts = BugsnagPerformanceSpanOptions()
        opts.setFirstClass(toTriState(string: scenarioConfig["opts_first_class"]))
        opts.metricsOptions.disk = toTriState(string: scenarioConfig["opts_metrics_disk"])
        let span = BugsnagPerformance.startSpan(name: spanName, options: opts)

        // Produce some disk activity inside the span so the byte counters
        // have a chance to advance. Best-effort - some hosts may still show
        // zero deltas.
        let workBytes = Int(toDouble(string: scenarioConfig["disk_work_bytes"]))
        if workBytes > 0 {
            self.doDiskWork(bytes: workBytes)
        }

        let spanDuration = toDouble(string: scenarioConfig["span_duration"])

        // End span + wait for batch flush to guarantee Maze Runner receives
        // the trace before the 30s step timeout.
        DispatchQueue.main.asyncAfter(deadline: .now() + spanDuration) {
            span.end()
            // Give the SDK time to package and upload the batch.
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                self.waitForCurrentBatch()
            }
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
