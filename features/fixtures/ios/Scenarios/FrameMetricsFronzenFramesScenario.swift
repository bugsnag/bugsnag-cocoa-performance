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
    
    override func configure() {
        super.configure()
        config.enabledMetrics.rendering = true
        config.internal.autoTriggerExportOnBatchSize = 3
    }
    
    override func run() {
        logError("###### START")
        let span = BugsnagPerformance.startSpan(name: "FrameMetricsFronzenFramesScenario")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            logError("###### 1")
            Thread.sleep(forTimeInterval: 0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                logError("###### 2")
                Thread.sleep(forTimeInterval: 0.8)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    logError("###### 3")
                    Thread.sleep(forTimeInterval: 0.4)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        logError("###### 4")
                        Thread.sleep(forTimeInterval: 1.0)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            logError("###### END")
                            span.end()
                        }
                    }
                }
            }
        }
    }
}
