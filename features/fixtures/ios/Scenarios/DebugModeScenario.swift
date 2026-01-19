//
//  DebugModeScenario.swift
//  Fixture
//
//  Created by Daria Bialobrzeska on 11/11/2025.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class DebugModeScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.isDevelopment = true
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 200
        bugsnagPerfConfig.internal.performWorkInterval = 60
    }

    override func run() {
        for i in 0..<30 {
            var spanName = "DebugModeScenario-\(i)"
            let span = BugsnagPerformance.startSpan(name: spanName)
            span.end()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            for i in 30..<60 {
                var spanName = "DebugModeScenario-\(i)"
                let span = BugsnagPerformance.startSpan(name: spanName)
                span.end()
            }
        }
    }
}
