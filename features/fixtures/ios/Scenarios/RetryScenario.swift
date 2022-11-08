//
//  RetryScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 08.11.22.
//

import BugsnagPerformance

class RetryScenario: Scenario {
    
    override func startBugsnag() {
        clearPersistentData()
        super.startBugsnag()
        bsg_autoTriggerExportOnBatchSize = 1
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "WillRetry").end()
        BugsnagPerformance.startSpan(name: "Success").end()
    }
}
