//
//  MaxPayloadSizeScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 30.06.23.
//

import BugsnagPerformance

@objcMembers
class MaxPayloadSizeScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.maxPackageContentLength = 10
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 1
        bugsnagPerfConfig.internal.performWorkInterval = 1
    }

    override func run() {
        BugsnagPerformance.startSpan(name: "MaxPayloadSizeScenario").end()
    }
}
