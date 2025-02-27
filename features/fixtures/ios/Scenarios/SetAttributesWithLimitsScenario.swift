//
//  SetAttributesWithLimitsScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 13.09.24.
//

import BugsnagPerformance

@objcMembers
class SetAttributesWithLimitsScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.attributeStringValueLimit = 10
        bugsnagPerfConfig.attributeArrayLengthLimit = 3
    }

    override func run() {
        let span = BugsnagPerformance.startSpan(name: "MySpan")
        span.setAttribute("a", withValue: "12345678901")
        span.setAttribute("b", withValue: [1, 2, 3, 4])
        span.end()
    }
}
