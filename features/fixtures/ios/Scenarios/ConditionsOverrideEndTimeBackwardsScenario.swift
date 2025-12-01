//
//  ConditionsOverrideEndTimeBackwardsScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 15/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

import BugsnagPerformance

@objcMembers
class ConditionsOverrideEndTimeBackwardsScenario: Scenario {

    override func run() {
        let span = BugsnagPerformance.startSpan(name: "ConditionsOverrideEndTimeBackwardsScenario")
        let condition2CloseTime = Date().addingTimeInterval(0.2)
        
        let condition1 = span.block(timeout: 0.1)
        condition1?.upgrade()
        let condition2 = span.block(timeout: 0.1)
        condition2?.upgrade()
        span.end()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            condition1?.close(endTime: Date())
            condition2?.close(endTime: condition2CloseTime)
        }
    }
}
