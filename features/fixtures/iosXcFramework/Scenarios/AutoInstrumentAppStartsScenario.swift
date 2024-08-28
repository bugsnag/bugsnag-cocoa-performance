//
//  AutoInstrumentAppStartsScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 07/10/2022.
//

import BugsnagPerformance

@objcMembers
class AutoInstrumentAppStartsScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.autoInstrumentAppStarts = true
    }

    override func run() {
    }
}
