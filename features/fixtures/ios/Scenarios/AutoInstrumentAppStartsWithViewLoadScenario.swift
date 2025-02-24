//
//  AutoInstrumentAppStartsWithViewLoadScenario.swift
//  Fixture
//
//  Created by Robert B on 20/02/2025.
//

import BugsnagPerformance

@objcMembers
class AutoInstrumentAppStartsWithViewLoadScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.autoInstrumentAppStarts = true
        config.autoInstrumentViewControllers = true
        // This test can generate a variable number of spans depending on the OS version,
        // so use a timed send instead.
        config.internal.autoTriggerExportOnBatchSize = 100
        config.internal.performWorkInterval = 1
    }

    override func run() {
        
    }
}
