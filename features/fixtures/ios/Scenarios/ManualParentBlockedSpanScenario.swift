//
//  ManualParentBlockedSpanScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 09/12/2025.
//

import BugsnagPerformance

@objcMembers
class ManualParentBlockedSpanScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 4;
    }

    override func run() {
        let parentSpan = BugsnagPerformance.startSpan(name: "ManualParentBlockedSpanScenarioParent")
        let blockedSpan1 = BugsnagPerformance.startSpan(name: "ManualParentBlockedSpanScenarioBlocked1")
        let blockedSpan2 = BugsnagPerformance.startSpan(name: "ManualParentBlockedSpanScenarioBlocked2")
        let condition1 = blockedSpan1.block(timeout: 1.0)
        condition1?.upgrade()
        blockedSpan1.end()
        let condition2 = blockedSpan2.block(timeout: 1.0)
        condition2?.upgrade()
        blockedSpan2.end()
        
        BugsnagPerformance.startSpan(name: "ManualParentBlockedSpanScenarioChild").end()
        parentSpan.end()
        
        condition1?.cancel()
        condition2?.cancel()
    }
}
