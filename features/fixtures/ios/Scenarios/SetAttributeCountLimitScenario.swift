//
//  SetAttributeCountLimitScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 16.09.24.
//

import BugsnagPerformance

@objcMembers
class SetAttributeCountLimitScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.attributeCountLimit = 3
    }

    override func run() {
        let span = BugsnagPerformance.startSpan(name: "SetAttributeCountLimitScenario")
        span.setAttribute("a", withValue: "12345678901")
        span.end()
    }
}
