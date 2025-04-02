//
//  MemoryMetricsScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 24.02.25.
//

import BugsnagPerformance

@objcMembers
class MemoryMetricsScenario: Scenario {
    override func run() {
        let runDelay = toDouble(string: scenarioConfig["run_delay"])
        DispatchQueue.main.asyncAfter(deadline: .now() + runDelay) {
            self.delayedRun()
        }
    }

    func delayedRun() {
        let opts = BugsnagPerformanceSpanOptions()
        opts.setFirstClass(toTriState(string: scenarioConfig["opts_first_class"]))
        opts.metricsOptions.memory = toTriState(string: scenarioConfig["opts_metrics_memory"])
        let span = BugsnagPerformance.startSpan(name: "MySpan", options: opts)
        let spanDuration = toDouble(string: scenarioConfig["span_duration"])
        DispatchQueue.main.asyncAfter(deadline: .now() + spanDuration) {
            span.end();
        }
    }
}
