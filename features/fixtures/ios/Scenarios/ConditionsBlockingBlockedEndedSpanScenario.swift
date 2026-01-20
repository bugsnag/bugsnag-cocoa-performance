//
//  ConditionsBlockingBlockedEndedSpanScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 15/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

import BugsnagPerformance

@objcMembers
class ConditionsBlockingBlockedEndedSpanScenario: Scenario {

    override func run() {
        let span = BugsnagPerformance.startSpan(name: "ConditionsBlockingBlockedEndedSpanScenario")
        let condition1 = span.block(timeout: 0.1)
        condition1?.upgrade()
        span.end()
        let condition2 = span.block(timeout: 0.1)
        condition2?.upgrade()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            condition1?.close(endTime: Date())
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                condition2?.close(endTime: Date())
            }
        }
    }
}
