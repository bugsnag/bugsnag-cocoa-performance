//
//  FirstClassNoScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 24.03.23.
//

import BugsnagPerformance

@objcMembers
class FirstClassNoScenario: Scenario {

    override func run() {
        let opts = BugsnagPerformanceSpanOptions().setFirstClass(.no)
        BugsnagPerformance.startSpan(name: "FirstClassNoScenario", options: opts).end()
    }
}
