//
//  ManualViewLoadPhaseScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 24.11.23.
//

import BugsnagPerformance

@objcMembers
class ManualViewLoadPhaseScenario: Scenario {
    override func run() {
        let options = BugsnagPerformanceSpanOptions().setStartTime(Date())
        let parentSpan = BugsnagPerformance.startViewLoadSpan(name: "ManualViewLoadPhaseScenario", viewType: .swiftUI, options:options)
        let phaseSpan = BugsnagPerformance.startViewLoadPhaseSpan(name: "ManualViewLoadPhaseScenario", phase: "SomePhase", parentContext: parentSpan)
        phaseSpan.end()
        parentSpan.end()
    }
}
