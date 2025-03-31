//
//  FrameMetricsAutoInstrumentRenderingOffScenario.swift
//  Fixture
//
//  Created by Robert B on 26/09/2024.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class FrameMetricsAutoInstrumentRenderingOffScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.enabledMetrics.rendering = false
    }
    
    override func run() {
        let span = BugsnagPerformance.startSpan(name: "FrameMetricsAutoInstrumentRenderingOffScenario")
        
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
