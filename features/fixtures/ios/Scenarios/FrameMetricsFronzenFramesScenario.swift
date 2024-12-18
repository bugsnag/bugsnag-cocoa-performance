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
        config.autoInstrumentRendering = true
        config.internal.autoTriggerExportOnBatchSize = 1
    }
    
    override func run() {
        logInfo("### START")
        let span = BugsnagPerformance.startSpan(name: "FrameMetricsFronzenFramesScenario")
        logInfo("### SPAN CREATED")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            logInfo("### SLEEPING FOR 0.3")
            Thread.sleep(forTimeInterval: 0.3)
            logInfo("### SLEPT FOR 0.3")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                logInfo("### SLEEPING FOR 0.8")
                Thread.sleep(forTimeInterval: 0.8)
                logInfo("### SLEPT FOR 0.8")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    logInfo("### SLEEPING FOR 0.4")
                    Thread.sleep(forTimeInterval: 0.4)
                    logInfo("### SLEPT FOR 0.4")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        logInfo("### SLEEPING FOR 1.0")
                        Thread.sleep(forTimeInterval: 1.0)
                        logInfo("### SLEEPING FOR 1.0")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            logInfo("### ENDING SPAN")
                            span.end()
                        }
                    }
                }
            }
        }
    }
}
