//
//  ReleaseStageNotEnabledScenario.swift
//  Fixture
//
//  Created by Robert B on 17/03/2023.
//

import BugsnagPerformance

@objcMembers
class ReleaseStageNotEnabledScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.releaseStage = "dev"
        config.enabledReleaseStages = Set(arrayLiteral: "staging", "release")
    }
    
    override func run() {
        BugsnagPerformance.startSpan(name: "Span1").end()
        BugsnagPerformance.startSpan(name: "Span2").end()
    }
}
