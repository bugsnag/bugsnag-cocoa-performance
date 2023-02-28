//
//  FirstClassNoScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 28.02.23.
//

import BugsnagPerformance

class FirstClassNoScenario: Scenario {
    
    override func run() {
        waitForCurrentBatch()
        var opts = BugsnagPerformanceSpanOptions()
        opts.isFirstClass = false;
        BugsnagPerformance.startSpan(name: "FirstClassNoScenario", options: opts).end()
    }
}
