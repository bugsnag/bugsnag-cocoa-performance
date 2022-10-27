//
//  SamplingProbabilityZeroScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 26/10/2022.
//

import BugsnagPerformance

class SamplingProbabilityZeroScenario: Scenario {
    
    override func startBugsnag() {
        config.autoInstrumentAppStarts = true
        config.autoInstrumentNetwork = true
        config.autoInstrumentViewControllers = true
        config.samplingProbability = 0
        super.startBugsnag()
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "Testing").end()
    }
}
