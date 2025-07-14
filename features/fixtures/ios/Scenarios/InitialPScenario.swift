//
//  InitialPScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 04.01.23.
//

import BugsnagPerformance

@objcMembers
class InitialPScenario: Scenario {
    let initialDelayBeforeSpans = 5.0

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.initialRecurringWorkDelay = initialDelayBeforeSpans
    }
    override func run() {
        // Wait to receive an initial P value response.
        Thread.sleep(forTimeInterval: initialDelayBeforeSpans + 0.1)
        BugsnagPerformance.startSpan(name: "First").end()
    }

    func step2() {
        BugsnagPerformance.startSpan(name: "Second").end()
    }
}
