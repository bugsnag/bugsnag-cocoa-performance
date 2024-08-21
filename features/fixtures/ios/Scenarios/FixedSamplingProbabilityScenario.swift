//
//  ServiceNameScenario.swift
//  Fixture
//
//  Created by Robert B on 20/08/2024.
//

import BugsnagPerformance

@objcMembers
class FixedSamplingProbabilityScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.samplingProbability = 1.0
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "FixedSamplingProbabilitySpan1").end()
    }
    
    func step2() {
        BugsnagPerformance.startSpan(name: "FixedSamplingProbabilitySpan2").end()
    }
}
