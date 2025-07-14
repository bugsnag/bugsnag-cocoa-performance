//
//  SamplingProbabilityZeroScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 26/10/2022.
//

import BugsnagPerformance

@objcMembers
class SamplingProbabilityZeroScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.initialSamplingProbability = 0
    }
    
    override func postLoad() {
        super.postLoad()
        BugsnagPerformance.startSpan(name: "Pre-start").end()
    }
    
    override func run() {
        // Wait for the initial P value response.
        waitForCurrentBatch()
        BugsnagPerformance.startSpan(name: "Post-start").end()
    }
}
