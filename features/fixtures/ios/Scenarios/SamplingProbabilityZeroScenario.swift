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
        config.autoInstrumentNetwork = true
        config.autoInstrumentViewControllers = true
        config.samplingProbability = 0
    }
    
    override func startBugsnag() {
        BugsnagPerformance.startSpan(name: "Pre-start").end()
        super.startBugsnag()
    }
    
    override func run() {
        // Make sure this happens after the app start span
        Thread.sleep(forTimeInterval: 0.1)
        BugsnagPerformance.startSpan(name: "Post-start").end()
    }
}
