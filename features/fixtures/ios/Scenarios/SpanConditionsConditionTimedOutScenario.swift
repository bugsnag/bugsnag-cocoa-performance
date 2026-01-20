//
//  SpanConditionsConditionTimedOutScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 31/01/2025.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class SpanConditionsConditionTimedOutScenario: Scenario {
    override func run() {
        let span1 = BugsnagPerformance.startSpan(name: "SpanConditionsConditionTimedOutScenarioSpan1")
        span1.block(timeout: 0.7)
        span1.end()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            let span2 = BugsnagPerformance.startSpan(name: "SpanConditionsConditionTimedOutScenarioSpan2")
            span2.end()
        })
    }
}
