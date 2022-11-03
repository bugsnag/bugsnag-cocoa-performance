//
//  BatchingScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 02.11.22.
//

import BugsnagPerformance

class BatchingScenario: Scenario {
    
    override func startBugsnag() {
        clearPersistentData()
        super.startBugsnag()
        bsg_autoTriggerExportOnBatchSize = 2
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "Span1").end()
        BugsnagPerformance.startSpan(name: "Span2").end()
    }
}
