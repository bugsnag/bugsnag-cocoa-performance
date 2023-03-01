//
//  InitialPScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 04.01.23.
//

import BugsnagPerformance

class InitialPScenario: Scenario {
    
    override func run() {
        waitForInitialPResponse()
        BugsnagPerformance.startSpan(name: "First").end()
        waitForCurrentBatch()
        BugsnagPerformance.startSpan(name: "Second").end()
    }
}
