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
        span.setAttribute("c", withValue: ["array_0", 1, true, 1.5])
        span.setAttribute("d", withValue: URL(string: "https://bugsnag.com"))
        span.setAttribute("e", withValue: [{}])
        span.setAttribute("f", withValue: [[]])
        span.setAttribute("x", withValue: [])
        span.end()
    }
}
