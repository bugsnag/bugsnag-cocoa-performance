//
//  FrameMetricsNonFirstClassSpanInstrumentRenderingOnScenario.swift
//  Fixture
//
//  Created by Robert B on 27/09/2024.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class FrameMetricsNonFirstClassSpanInstrumentRenderingOnScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.enabledMetrics.rendering = true
    }
    
    override func run() {
        let options = BugsnagPerformanceSpanOptions()
        options.metricsOptions.rendering = (.yes)
        options.setFirstClass(.no)
        let span = BugsnagPerformance.startSpan(name: "FrameMetricsNonFirstClassSpanInstrumentRenderingOnScenario", options: options)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Thread.sleep(forTimeInterval: 0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Thread.sleep(forTimeInterval: 0.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    Thread.sleep(forTimeInterval: 0.2)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        span.end()
                    }
                }
            }
        }
    }
}
