//
//  RetryScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 08.11.22.
//

import BugsnagPerformance

class RetryScenario: Scenario {
    
    override func run() {
        Thread.sleep(forTimeInterval: 0.5)
        BugsnagPerformance.startSpan(name: "WillRetry").end()
        Thread.sleep(forTimeInterval: 0.5)
        BugsnagPerformance.startSpan(name: "Success").end()
    }
}
