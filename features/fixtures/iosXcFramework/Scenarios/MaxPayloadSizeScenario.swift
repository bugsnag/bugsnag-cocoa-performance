//
//  MaxPayloadSizeScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 30.06.23.
//

import BugsnagPerformance

@objcMembers
class MaxPayloadSizeScenario: Scenario {

    override func configure() {
        super.configure()
        config.internal.maxPackageContentLength = 10
        config.internal.autoTriggerExportOnBatchSize = 1
        config.internal.performWorkInterval = 1
    }

    override func run() {
        BugsnagPerformance.startSpan(name: "MaxPayloadSizeScenario").end()
    }
}
