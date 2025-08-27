//
//  ManualSpanWithContextParentNilScenario.swift
//  Fixture
//
//  Created by Daria Bialobrzeska on 27/08/2025.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class ManualSpanWithContextParentNilScenario: Scenario {

    override func run() {
        let opts = BugsnagPerformanceSpanOptions()
        opts.setParentContext(nil)
        let span = BugsnagPerformance.startSpan(
            name: "ManualSpanWithContextParentNilScenario",
            options: opts
        )
        span.end()
    }
}
