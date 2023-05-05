//
//  ManualSpanBeforeStartScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 04/10/2022.
//

import BugsnagPerformance

class ManualSpanBeforeStartScenario: Scenario {
    
    override func startBugsnag() {
        BugsnagPerformance.startSpan(name: "BeforeStart").end()
        super.startBugsnag()
    }

    override func run() {
    }
}
