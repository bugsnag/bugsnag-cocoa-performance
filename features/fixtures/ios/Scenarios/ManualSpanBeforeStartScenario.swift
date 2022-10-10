//
//  ManualSpanBeforeStartScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 04/10/2022.
//

import BugsnagPerformance

class ManualSpanBeforeStartScenario: Scenario {
    
    override init() {
        BugsnagPerformance.startSpan(name: "BeforeStart").end()
    }
    
    override func run() {
    }
}
