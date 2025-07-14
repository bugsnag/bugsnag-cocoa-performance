//
//  RenderingMetricsScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 26.02.25.
//

import BugsnagPerformance

enum SpanStartTime {
    case early, normal, late
}

@objcMembers
class RenderingMetricsScenario: Scenario {

    var span: BugsnagPerformanceSpan? = nil

    override func startBugsnag() {
        logError("### RenderingMetricsScenario.configure()")
        if getSpanStartTime() == .early {
            logError("### RenderingMetricsScenario.configure(): Starting span early")
            startSpan()
        }

        logError("### RenderingMetricsScenario.configure(): running super configure")
        super.startBugsnag()
    }

    override func run() {
        logError("### RenderingMetricsScenario.run()")
        switch getSpanStartTime() {
        case .early:
            logError("### RenderingMetricsScenario.run(): early")
            performSpanEnd()
        case .normal:
            logError("### RenderingMetricsScenario.run(): normal")
            startSpan()
            performSpanEnd()
        case .late:
            logError("### RenderingMetricsScenario.run(): late")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startSpan()
                self.performSpanEnd()
            }
        }
    }

    // ----------------------------------------

    func getSpanStartTime() -> SpanStartTime {
        logError("### getSpanStartTime(): Scenario config = \(String(describing: scenarioConfig["spanStartTime"]))")
        switch scenarioConfig["spanStartTime"] {
        case "early":
            logError("### getSpanStartTime(): Returning .early")
            return .early
        case "late":
            logError("### getSpanStartTime(): Returning .late")
            return .late
        default:
            logError("### getSpanStartTime(): Returning .normal")
            return .normal
        }
    }

    func performSpanEnd() {
        switch scenarioConfig["frameDelay"] {
        case "slow":
            slowFrameAndSpanEnd()
        case "frozen":
            frozenFrameAndSpanEnd()
        default:
            normalSpanEnd()
        }
    }

    func normalSpanEnd() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.endSpan()
            self.waitForBrowserstack()
        }
    }

    func slowFrameAndSpanEnd() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Thread.sleep(forTimeInterval: 0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Thread.sleep(forTimeInterval: 0.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    Thread.sleep(forTimeInterval: 0.2)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.endSpan()
                        self.waitForBrowserstack()
                    }
                }
            }
        }
    }

    func frozenFrameAndSpanEnd() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Thread.sleep(forTimeInterval: 0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                Thread.sleep(forTimeInterval: 0.8)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    Thread.sleep(forTimeInterval: 0.4)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        Thread.sleep(forTimeInterval: 1.0)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            self.endSpan()
                            self.waitForBrowserstack()
                        }
                    }
                }
            }
        }
    }

    func startSpan() {
        let opts = BugsnagPerformanceSpanOptions()
        opts.setFirstClass(toTriState(string: scenarioConfig["opts.firstClass"]))
        opts.metricsOptions.rendering = toTriState(string: scenarioConfig["opts.metrics.rendering"])
        span = BugsnagPerformance.startSpan(name: spanName, options: opts)
        logError("### startSpan(): Span = \(String(describing: span))")
    }

    func endSpan() {
        logError("### endSpan(): Span = \(String(describing: span))")
        span!.end()
    }
}
