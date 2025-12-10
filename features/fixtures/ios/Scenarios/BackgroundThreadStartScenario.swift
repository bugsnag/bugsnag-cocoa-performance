//
//  BackgroundThreadStartScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 09/12/2025.
//

import BugsnagPerformance

@objcMembers
class BackgroundThreadStartScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        
        // Ensure the batch doesn't get full, as we want the spans to be delivered due to reaching work interval
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
        bugsnagPerfConfig.internal.performWorkInterval = 5.0
    }
    
    override func startBugsnag() {
        BugsnagPerformance.startSpan(name: "BackgroundThreadStartScenarioEarlySpan").end()
        DispatchQueue
            .global(qos: .background)
            .asyncAfter(deadline: .now() + 2.0) {
            super.startBugsnag()
        }
    }

    override func run() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            BugsnagPerformance.startSpan(name: "BackgroundThreadStartScenarioSpan").end()
        }
    }
}
