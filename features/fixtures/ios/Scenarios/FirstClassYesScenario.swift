//
//  FirstClassYesScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 24.03.23.
//

import BugsnagPerformance

class FirstClassYesScenario: Scenario {

    override func run() {
        let opts = BugsnagPerformanceSpanOptions()
        opts.firstClass = BSGFirstClass.yes;
        BugsnagPerformance.startSpan(name: "FirstClassYesScenario", options: opts).end()
    }
}
