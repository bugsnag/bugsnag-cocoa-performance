//
//  AutoInstrumentAppStartsScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 07/10/2022.
//

import BugsnagPerformance

class AutoInstrumentAppStartsScenario: Scenario {

    override func configure() {
        super.configure()
        bsgp_autoTriggerExportOnBatchSize = 100
        bsgp_performWorkInterval = 1000
        config.autoInstrumentAppStarts = true
    }

//    override func startBugsnag() {
//        BugsnagPerformance.startViewLoadSpan(name: "AutoInstrumentAppStartsScenarioView", viewType: .uiKit)
//        super.startBugsnag()
//    }
    
//    override func run() {
//        waitForCurrentBatch()
//    }
}
