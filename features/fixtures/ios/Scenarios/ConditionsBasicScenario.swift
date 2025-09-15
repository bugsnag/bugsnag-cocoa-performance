//
//  ConditionsBasicScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 15/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

import BugsnagPerformance

@objcMembers
class ConditionsBasicScenario: Scenario {

    override func run() {
        let span = BugsnagPerformance.startSpan(name: "ConditionsBasicScenario")
        let condition = span.block(timeout: 0.1)
        condition?.upgrade()
        span.end()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            condition?.close(endTime: Date())
        }
    }
}
