//
//  ManualSpanScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import BugsnagPerformance

class ManualSpanScenario: Scenario {
    
    override func run() {
        BugsnagPerformance.startSpan(name: "ManualSpanScenario").end()
    }
}
