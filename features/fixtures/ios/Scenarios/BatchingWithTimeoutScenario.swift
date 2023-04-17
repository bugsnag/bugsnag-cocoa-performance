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
        NSLog("###### BatchingWithTimeoutScenario: bsgp_autoTriggerExportOnBatchSize was %d", bsgp_autoTriggerExportOnBatchSize)
        bsgp_autoTriggerExportOnBatchSize = 130;
        NSLog("###### BatchingWithTimeoutScenario: bsgp_autoTriggerExportOnBatchSize is %d", bsgp_autoTriggerExportOnBatchSize)
        bsgp_performWorkInterval = 10;
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "Span1").end()
        sleep(1)
    }
}
