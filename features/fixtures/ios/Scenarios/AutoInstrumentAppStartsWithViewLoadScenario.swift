//
//  AutoInstrumentAppStartsWithViewLoadScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 20/02/2025.
//

import BugsnagPerformance

@objcMembers
class AutoInstrumentAppStartsWithViewLoadScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentAppStarts = true
        bugsnagPerfConfig.autoInstrumentViewControllers = true
        // This test can generate a variable number of spans depending on the OS version,
        // so use a timed send instead.
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
        bugsnagPerfConfig.internal.performWorkInterval = 1
    }

    override func run() {
        
    }
}
