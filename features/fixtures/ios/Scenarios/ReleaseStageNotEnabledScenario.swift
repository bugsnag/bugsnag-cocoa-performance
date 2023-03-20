//
//  ReleaseStageNotEnabledScenario.swift
//  Fixture
//
//  Created by Robert B on 17/03/2023.
//

import BugsnagPerformance

class ReleaseStageNotEnabledScenario: Scenario {
    
    override func startBugsnag() {
        config.releaseStage = "dev"
        config.enabledReleaseStages = Set(arrayLiteral: "staging", "release")
        super.startBugsnag()
    }
    
    override func run() {
        waitForCurrentBatch()
        BugsnagPerformance.startSpan(name: "Span1").end()
        BugsnagPerformance.startSpan(name: "Span2").end()
    }
}
