//
//  ManualSpanWithRemoteContextParentScenario.swift
//  Fixture
//
//  Created by Robert B on 08/05/2025.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class ManualSpanWithRemoteContextParentScenario: Scenario {

    override func run() {
        let context = BugsnagPerformanceRemoteSpanContext(traceParentString: "00-a053e37f6d56592bc15a2c13c3c688ff-eeb87b8b7cde2185-01")
        let opts = BugsnagPerformanceSpanOptions()
        opts.setParentContext(context)
        let span = BugsnagPerformance.startSpan(
            name: "ManualSpanWithRemoteContextParentScenario",
            options: opts
        )
        span.end()
    }
}
