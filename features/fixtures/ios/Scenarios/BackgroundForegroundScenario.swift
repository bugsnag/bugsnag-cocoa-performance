//
//  BackgroundForegroundScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 10.03.23.
//

import BugsnagPerformance

class BackgroundForegroundScenario: Scenario {
    
    override func configure() {
        super.configure()
        bsgp_autoTriggerExportOnBatchSize = 100
        bsgp_performWorkInterval = 1000
    }
    
//    override func startBugsnag() {
//        BugsnagPerformance.startSpan(name: "Pre-start").end()
//        super.startBugsnag()
//    }

    override func run() {
        waitForCurrentBatch()
        BugsnagPerformance.startSpan(name: "BackgroundForegroundScenario").end()
    }
}
