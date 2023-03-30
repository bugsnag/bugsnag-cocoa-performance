//
//  AutoInstrumentAppStartsScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 07/10/2022.
//

import BugsnagPerformance

class AutoInstrumentAppStartsScenario: Scenario {
    
    override func startBugsnag() {
        config.autoInstrumentAppStarts = true
        BugsnagPerformance.startViewLoadSpan(name: "AutoInstrumentAppStartsScenarioView", viewType: .uiKit)
        super.startBugsnag()
    }
    
    override func run() {
    }
}
