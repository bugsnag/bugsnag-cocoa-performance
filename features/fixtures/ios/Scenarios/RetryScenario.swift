//
//  RetryScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 08.11.22.
//

import BugsnagPerformance

@objcMembers
class RetryScenario: Scenario {
    
    override func run() {
        BugsnagPerformance.startSpan(name: "WillRetry").end()
    }

    func step2() {
        BugsnagPerformance.startSpan(name: "Success").end()
    }
}
