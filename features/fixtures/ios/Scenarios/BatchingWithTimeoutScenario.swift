//
//  BatchingScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 02.11.22.
//

import BugsnagPerformance

@objcMembers
class BatchingWithTimeoutScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
        bugsnagPerfConfig.internal.performWorkInterval = 10
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "Span1").end()
    }
}
