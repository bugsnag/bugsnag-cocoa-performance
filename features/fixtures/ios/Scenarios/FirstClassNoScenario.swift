//
//  FirstClassNoScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 24.03.23.
//

import BugsnagPerformance

class FirstClassNoScenario: Scenario {

    override func run() {
        waitForCurrentBatch()
        let opts = BugsnagPerformanceSpanOptions()
        opts.firstClass = BSGFirstClass.no;
        BugsnagPerformance.startSpan(name: "FirstClassNoScenario", options: opts).end()
    }
}
