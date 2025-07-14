//
//  FrameMetricsFronzenFramesScenario.swift
//  Fixture
//
//  Created by Robert B on 20/09/2024.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class FrameMetricsFronzenFramesScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.enabledMetrics.rendering = true
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 3
    }
    
    override func run() {
        let span = BugsnagPerformance.startSpan(name: "FrameMetricsFronzenFramesScenario")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Thread.sleep(forTimeInterval: 0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                Thread.sleep(forTimeInterval: 0.8)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    Thread.sleep(forTimeInterval: 0.4)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        Thread.sleep(forTimeInterval: 1.0)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            span.end()
                            // Force sleep so that Browserstack doesn't prematurely shut down the app while BugsnagPerformanceImpl delays for sampling.
                            Thread.sleep(forTimeInterval: 2)
                        }
                    }
                }
            }
        }
    }
}
