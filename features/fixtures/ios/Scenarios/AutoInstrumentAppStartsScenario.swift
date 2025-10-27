//
//  AutoInstrumentAppStartsScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 07/10/2022.
//

import BugsnagPerformance

@objcMembers
class AutoInstrumentAppStartsScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentAppStarts = true
        bugsnagPerfConfig.enabledMetrics.cpu = true
        bugsnagPerfConfig.enabledMetrics.memory = true
    }

    override func run() {
    }
}
