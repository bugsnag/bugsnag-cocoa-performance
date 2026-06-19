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
        // Read config from scenarioConfig dictionary (NOT instance properties)
        let sessionType = scenarioConfig["session_type"] ?? "manual session"
        let duration = toDouble(string: scenarioConfig["span_duration"]) > 0
            ? toDouble(string: scenarioConfig["span_duration"])
            : 5.0
        let shouldAbort = toBool(string: scenarioConfig["abort_span"])
        let workDur = toDouble(string: scenarioConfig["work_duration"])
        let workThread = scenarioConfig["work_on_thread"] ?? "main"
        let concurrentSessionType = scenarioConfig["concurrent_session_type"]
        NSLog("App session_type=\(sessionType), duration=\(duration), abort=\(shouldAbort)")
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
            // Scenarios 2-5, 7: app session spans
            let sessionTypeId = toPascalCase(sessionType)
            let appSessionSpanName = "[AppSession/\(sessionTypeId)]"
            NSLog("App Starting session span: \(appSessionSpanName)")
            let opts = BugsnagPerformanceSpanOptions()
            _ = opts.setFirstClass(.yes)
            _ = opts.setMakeCurrentContext(false)
            self.sessionSpan = BugsnagPerformance.startSpan(
                name: appSessionSpanName,
                options: opts
            )
            sessionSpan?.setAttribute("bugsnag.span.category", withValue: "app_session")
            sessionSpan?.setAttribute("bugsnag.app_session.name", withValue: sessionTypeId)
            // --- Concurrent session support ---
            var concurrentSpan: BugsnagPerformanceSpan?
            if let concurrentType = concurrentSessionType, !concurrentType.isEmpty {
                let concurrentTypeId = toPascalCase(concurrentType)
                let concurrentSpanName = "[AppSession/\(concurrentTypeId)]"
                NSLog("App Starting concurrent session span: \(concurrentSpanName)")
                let concurrentOpts = BugsnagPerformanceSpanOptions()
                _ = concurrentOpts.setFirstClass(.yes)
                _ = concurrentOpts.setMakeCurrentContext(false)
                concurrentSpan = BugsnagPerformance.startSpan(
                    name: concurrentSpanName,
                    options: concurrentOpts
                )
                concurrentSpan?.setAttribute("bugsnag.span.category", withValue: "app_session")
                concurrentSpan?.setAttribute("bugsnag.app_session.name", withValue: concurrentTypeId)
            }
            // CPU work if configured
            if workDur > 0 {
                NSLog("App Doing CPU work for \(workDur)s on \(workThread)")
                if workThread == "main" {
                    doBusyWork(forDuration: workDur)
                } else {
                    DispatchQueue.global().async {
                        self.doBusyWork(forDuration: workDur)
                    }
                    Thread.sleep(forTimeInterval: workDur)
                }
            }
            Thread.sleep(forTimeInterval: duration)
            if shouldAbort {
                NSLog("App Aborting session span")
                sessionSpan = nil
            } else {
                NSLog("App Ending session span")
                sessionSpan?.end()
            }
            sessionSpan = nil
            // --- End concurrent session span ---
            if let activeConc = concurrentSpan {
                NSLog("App Ending concurrent session span")
                activeConc.end()
                concurrentSpan = nil
            }
            waitForBrowserstack()
        }
    }
    func toPascalCase(_ input: String) -> String {
        let acronyms: Set<String> = ["cpu", "gpu", "api", "url", "id"]
        return input
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { word in
                if acronyms.contains(word.lowercased()) {
                    return word.uppercased()
                }
                return word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined()
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
