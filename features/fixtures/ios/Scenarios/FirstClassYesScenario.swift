//
//  FirstClassYesScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 24.03.23.
//

import BugsnagPerformance

@objcMembers
class FirstClassYesScenario: Scenario {

    override func run() {
        let opts = BugsnagPerformanceSpanOptions().setFirstClass(.yes)
        BugsnagPerformance.startSpan(name: "FirstClassYesScenario", options: opts).end()
    }
}
