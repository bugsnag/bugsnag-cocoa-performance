//
//  BatchingScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 02.11.22.
//

import BugsnagPerformance

class BatchingWithTimeoutScenario: Scenario {
    
    override func startBugsnag() {
        super.startBugsnag()
        bsgp_autoTriggerExportOnBatchSize = 100;
        bsgp_performWorkInterval = 10;
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "Span1").end()
        sleep(1)
    }
}
