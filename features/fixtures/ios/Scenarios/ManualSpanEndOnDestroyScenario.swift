//
//  ManualSpanEndOnDestroyScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 27/10/2025.
//

import BugsnagPerformance

@objcMembers
class ManualSpanEndOnDestroyScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 1;
    }

    override func run() {
        let opts = BugsnagPerformanceSpanOptions()
        opts.setFirstClass(.yes)
        let span = BugsnagPerformance.startSpan(
            name: spanName,
            options: opts
        )
        span.setAttribute("TestString", withValue: "test")
        span.endOnDestroy()
    }
}
