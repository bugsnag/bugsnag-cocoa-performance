//
//  InitialPScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 04.01.23.
//

import BugsnagPerformance

@objcMembers
class InitialPScenario: Scenario {

    override func configure() {
        super.configure()
        config.internal.initialRecurringWorkDelay = 0
    }
    override func run() {
        // Wait to receive an initial P value response.
        waitForCurrentBatch()
        BugsnagPerformance.startSpan(name: "First").end()
    }

    func step2() {
        BugsnagPerformance.startSpan(name: "Second").end()
    }
}
