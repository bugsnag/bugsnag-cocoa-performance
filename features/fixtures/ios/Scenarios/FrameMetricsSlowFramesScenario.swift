//
//  FrameMetricsSlowFramesScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 20/09/2024.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class FrameMetricsSlowFramesScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.enabledMetrics.rendering = true
    }
    
    override func run() {
        let span = BugsnagPerformance.startSpan(name: "FrameMetricsSlowFramesScenario")
        
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
