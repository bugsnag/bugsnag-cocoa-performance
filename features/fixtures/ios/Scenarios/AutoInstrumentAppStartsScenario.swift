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
        NSLog("###### AutoInstrumentAppStartsScenario: bsgp_autoTriggerExportOnBatchSize was %d", bsgp_autoTriggerExportOnBatchSize)
        bsgp_autoTriggerExportOnBatchSize = 4
        NSLog("###### AutoInstrumentAppStartsScenario: bsgp_autoTriggerExportOnBatchSize = %d", bsgp_autoTriggerExportOnBatchSize)
        BugsnagPerformance.startViewLoadSpan(name: "AutoInstrumentAppStartsScenarioView", viewType: .uiKit)
        super.startBugsnag()
    }
    
    override func run() {
        waitForCurrentBatch()
    }
}
