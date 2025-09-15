//
//  SpanConditionsSimpleConditionScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 31/01/2025.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class SpanConditionsSimpleConditionScenario: Scenario {
    override func run() {
        let span1 = BugsnagPerformance.startSpan(name: "SpanConditionsSimpleConditionScenarioSpan1")
        let condition = span1.block(timeout: 0.5)
        span1.end()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            let upgradeSpan = condition?.upgrade()
            let options = BugsnagPerformanceSpanOptions()
            options.setParentContext(upgradeSpan)
            let span2 = BugsnagPerformance.startSpan(name: "SpanConditionsSimpleConditionScenarioSpan2", options: options)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                span2.end()
                condition?.close(endTime: Date())
            })
        })
    }
}
