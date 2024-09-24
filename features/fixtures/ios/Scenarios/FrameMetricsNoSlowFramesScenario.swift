//
//  FrameMetricsNoSlowFramesScenario.swift
//  Fixture
//
//  Created by Robert B on 20/09/2024.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class FrameMetricsNoSlowFramesScenario: Scenario {
    
    override func run() {
        let span = BugsnagPerformance.startSpan(name: "FrameMetricsNoSlowFramesScenario")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            span.end()
        }
    }
}
