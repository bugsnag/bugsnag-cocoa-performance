//
//  CPUMetricsScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 22.01.25.
//

import BugsnagPerformance

@objcMembers
class CPUMetricsScenario: Scenario {
    override func run() {
        let runDelay = toDouble(string: scenarioConfig["run_delay"])
        DispatchQueue.main.asyncAfter(deadline: .now() + runDelay) {
            self.delayedRun()
        }

        let workDuration = toDouble(string: scenarioConfig["work_duration"])
        if workDuration > 0 {
            var queue = DispatchQueue.global()
            if scenarioConfig["work_on_thread"] == "main" {
                queue = DispatchQueue.main
            }
            queue.asyncAfter(deadline: .now()) {
                self.doBusyWork(forSeconds: workDuration);
            }
        }
    }

    func delayedRun() {
        let opts = BugsnagPerformanceSpanOptions()
        opts.setFirstClass(toTriState(string: scenarioConfig["opts_first_class"]))
        opts.metricsOptions.cpu = toTriState(string: scenarioConfig["opts_metrics_cpu"])
        let span = BugsnagPerformance.startSpan(name: spanName, options: opts)
        let spanDuration = toDouble(string: scenarioConfig["span_duration"])
        DispatchQueue.main.asyncAfter(deadline: .now() + spanDuration) {
            span.end();
        }
    }

    func doBusyWork(forSeconds: Double) {
        let deadline = Date().addingTimeInterval(forSeconds);
        let values = Array(0...1000000)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        var encoded = try! encoder.encode(values)
        var decoded = try! decoder.decode(Array<Int>.self, from: encoded)
        while(Date() < deadline) {
            encoded = try! encoder.encode(decoded)
            decoded = try! decoder.decode(Array<Int>.self, from: encoded)
        }
    }
}
