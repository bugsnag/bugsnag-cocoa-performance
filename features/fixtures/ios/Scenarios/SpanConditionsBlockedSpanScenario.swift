//
//  SpanConditionsBlockedSpanScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 31/01/2025.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class SpanConditionsBlockedSpanScenario: Scenario {
    override func run() {
        let span1 = BugsnagPerformance.startSpan(name: "SpanConditionsBlockedSpanScenarioSpan1")
        let span2 = BugsnagPerformance.startSpan(name: "SpanConditionsBlockedSpanScenarioSpan2")
        span1.block(timeout: 0.3)
        span1.end()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            span2.end()
            let condition = span1.block(timeout: 0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                condition?.close(endTime: Date())
            })
        })
    }
}
