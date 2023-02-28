//
//  FirstClassYesScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 28.02.23.
//

import BugsnagPerformance

class FirstClassYesScenario: Scenario {
    
    override func run() {
        waitForCurrentBatch()
        BugsnagPerformance.startSpan(name: "FirstClassYesScenario").end()
    }
}
