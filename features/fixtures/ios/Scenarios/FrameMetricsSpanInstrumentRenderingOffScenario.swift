//
//  FrameMetricsSpanInstrumentRenderingOffScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 26/09/2024.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class FrameMetricsSpanInstrumentRenderingOffScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.enabledMetrics.rendering = true
    }
    
    override func run() {
        let options = BugsnagPerformanceSpanOptions()
        options.metricsOptions.rendering = (.no)
        let span = BugsnagPerformance.startSpan(name: "FrameMetricsSpanInstrumentRenderingOffScenario", options: options)
        
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
