//
//  ManualParentSpanScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 01.07.24.
//

import BugsnagPerformance

@objcMembers
class ManualParentSpanScenario: Scenario {

    override func configure() {
        super.configure()
        config.internal.autoTriggerExportOnBatchSize = 1;
    }

    override func run() {
        let opts = BugsnagPerformanceSpanOptions()
        opts.setParentContext(BugsnagPerformanceSpanContext(traceIdHi: 0x123456789abcdef0,
                                                    traceIdLo: 0xfedcba9876543210,
                                                    spanId: 0x23456789abcdef01))
        let spanChild = BugsnagPerformance.startSpan(name: "SpanChild", options: opts)
        spanChild.end()
    }
}
