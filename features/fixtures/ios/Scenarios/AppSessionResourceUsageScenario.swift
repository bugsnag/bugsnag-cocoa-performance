//
//  AppSessionResourceUsageScenario.swift
//  BugsnagPerformance
//
//  Created by Meiyalagan Ramadurai on 15/06/26.
//

import BugsnagPerformance

@objcMembers
class AppSessionResourceUsageScenario: Scenario {
    var sessionSpan: BugsnagPerformanceSpan?
    override func run() {
        let sessionType = scenarioConfig["session_type"] ?? "manual session"
        let duration = toDouble(string: scenarioConfig["span_duration"]) > 0
        ? toDouble(string: scenarioConfig["span_duration"])
        : 5.0
        let shouldAbort = toBool(string: scenarioConfig["abort_span"])
        let workDur = toDouble(string: scenarioConfig["work_duration"])
        let workThread = scenarioConfig["work_on_thread"] ?? "main"
        let concurrentSessionType = scenarioConfig["concurrent_session_type"]
        if sessionType == "manual session" {
            // Scenario 1: simple manual span
            let opts = BugsnagPerformanceSpanOptions()
            _ = opts.setFirstClass(.yes)
            self.sessionSpan = BugsnagPerformance.startSpan(
                name: "TestManualSpan",
                options: opts
            )
            Thread.sleep(forTimeInterval: 2.0)
            sessionSpan?.end()
            waitForBrowserstack()
        } else {
            // Use the real app session API — SDK handles span name, category,
            // and attaches resource usage aggregation (mean, min, max)
            self.sessionSpan = BugsnagPerformance.startAppSessionSpan(sessionType)
            // --- Concurrent session support ---
            var concurrentSpan: BugsnagPerformanceSpan?
            if let concurrentType = concurrentSessionType, !concurrentType.isEmpty {
                concurrentSpan = BugsnagPerformance.startAppSessionSpan(concurrentType)
            }
            // CPU work if configured
            if workDur > 0 {
                if workThread == "main" {
                    doBusyWork(forDuration: workDur)
                } else {
                    DispatchQueue.global().async {
                        self.doBusyWork(forDuration: workDur)
                    }
                    Thread.sleep(forTimeInterval: workDur)
                }
            }
            // Child span support (for parent check scenario)
            if toBool(string: scenarioConfig["create_child_span"]) {
                let childOpts = BugsnagPerformanceSpanOptions()
                _ = childOpts.setFirstClass(.yes)
                _ = childOpts.setMakeCurrentContext(false)
                let childSpan = BugsnagPerformance.startSpan(
                    name: "ChildSpanInsideSession",
                    options: childOpts
                )
                childSpan.setAttribute("bugsnag.span.category", withValue: "custom")
                Thread.sleep(forTimeInterval: 0.5)
                childSpan.end()
            }
            
            Thread.sleep(forTimeInterval: duration)
            if shouldAbort {
                sessionSpan = nil
            } else {
                sessionSpan?.end()
            }
            sessionSpan = nil
            // --- End concurrent session span ---
            if let activeConc = concurrentSpan {
                activeConc.end()
                concurrentSpan = nil
            }
            
            // Give SDK time to flush all spans before Maze Runner checks
            Thread.sleep(forTimeInterval: 5.0)
            waitForBrowserstack()
        }
    }
    func doBusyWork(forDuration duration: TimeInterval) {
        let end = Date(timeIntervalSinceNow: duration)
        var value: Double = 0
        while Date() < end {
            for i in 0..<10000 {
                value += sqrt(Double(i))
            }
        }
        _ = value
    }
}
