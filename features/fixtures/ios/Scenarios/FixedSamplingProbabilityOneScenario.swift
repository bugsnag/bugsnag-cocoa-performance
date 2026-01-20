//
//  ServiceNameScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 20/08/2024.
//

import BugsnagPerformance

@objcMembers
class FixedSamplingProbabilityOneScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.samplingProbability = 1.0
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "FixedSamplingProbabilitySpan1").end()
    }
    
    func step2() {
        BugsnagPerformance.startSpan(name: "FixedSamplingProbabilitySpan2").end()
    }
}
