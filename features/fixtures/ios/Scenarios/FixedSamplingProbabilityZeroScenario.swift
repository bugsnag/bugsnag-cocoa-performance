//
//  FixedSamplingProbabilityZeroScenario.swift
//  Fixture
//
//  Created by Robert B on 23/08/2024.
//

import BugsnagPerformance

@objcMembers
class FixedSamplingProbabilityZeroScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.samplingProbability = 0.0
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "FixedSamplingProbabilitySpan1").end()
    }
}
