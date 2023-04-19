//
//  BatchingScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 02.11.22.
//

import BugsnagPerformance

class BatchingWithTimeoutScenario: Scenario {

    override func configure() {
        super.configure()
        config.internal.autoTriggerExportOnBatchSize = 100
        config.internal.performWorkInterval = 10
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "Span1").end()
        sleep(1)
    }
}
