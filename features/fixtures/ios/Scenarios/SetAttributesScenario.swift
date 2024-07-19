//
//  SetAttributesScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 19.07.24.
//

import BugsnagPerformance

@objcMembers
class SetAttributesScenario: Scenario {
    
    override func run() {
        let span = BugsnagPerformance.startSpan(name: "MySpan")
        span.setAttribute("a", withValue: "xyz")
        span.setAttribute("b", withValue: "abc")
        span.setAttribute("b", withValue: nil)
        span.setAttribute("x", withValue: [])
        span.end()
    }
}
