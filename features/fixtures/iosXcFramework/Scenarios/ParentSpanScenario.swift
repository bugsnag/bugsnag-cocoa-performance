//
//  ParentSpanScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 21.02.23.
//

import BugsnagPerformance

@objcMembers
class ParentSpanScenario: Scenario {

    override func configure() {
        super.configure()
        config.internal.autoTriggerExportOnBatchSize = 2;
    }

    override func run() {
        let spanParent = BugsnagPerformance.startSpan(name: "SpanParent")
        let spanChild = BugsnagPerformance.startSpan(name: "SpanChild")
        spanChild.end()
        spanParent.end();
    }
}
