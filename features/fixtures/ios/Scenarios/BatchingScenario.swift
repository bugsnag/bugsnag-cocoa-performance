//
//  BatchingScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 02.11.22.
//

import BugsnagPerformance

class BatchingScenario: Scenario {

    override func configure() {
        super.configure()
        config.internal.autoTriggerExportOnBatchSize = 2
    }
    
    override func run() {
        waitForCurrentBatch()
        BugsnagPerformance.startSpan(name: "Span1").end()
        BugsnagPerformance.startSpan(name: "Span2").end()
    }
}
