//
//  SamplingProbabilityZeroScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 26/10/2022.
//

import BugsnagPerformance

class SamplingProbabilityZeroScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.autoInstrumentAppStarts = true
        config.autoInstrumentNetworkRequests = true
        config.autoInstrumentViewControllers = true
        config.samplingProbability = 0
    }
    
    override func startBugsnag() {
        BugsnagPerformance.startSpan(name: "Pre-start").end()
        super.startBugsnag()
    }
    
    override func run() {
        // Wait for the initial P value response.
        waitForCurrentBatch()
        BugsnagPerformance.startSpan(name: "Post-start").end()
    }
}
