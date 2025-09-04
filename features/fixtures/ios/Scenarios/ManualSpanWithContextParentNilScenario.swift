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
        let emptyOpts = BugsnagPerformanceSpanOptions()
        let shouldNotBeParentSpan = BugsnagPerformance.startSpan(
            name: "ShouldNotBeParentSpan",
            options: emptyOpts
        )

        let opts = BugsnagPerformanceSpanOptions()
        opts.setParentContext(nil)
        let span = BugsnagPerformance.startSpan(
            name: "ManualSpanWithContextParentNilScenario",
            options: opts
        )
        span.end()


        let spanWithParent = BugsnagPerformance.startSpan(
            name: "ManualSpanWithContextParentSet",
            options: emptyOpts
        )
        spanWithParent.end()


        shouldNotBeParentSpan.end()
    }
}
