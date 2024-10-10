//
//  ManualViewLoadScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 10/10/2022.
//

import BugsnagPerformance

@objcMembers
class ManualViewLoadScenario: Scenario {
    
    override func run() {
        BugsnagPerformance.startViewLoadSpan(name: "ManualViewController", viewType: .uiKit).end()
        let options = BugsnagPerformanceSpanOptions().setStartTime(Date())
        BugsnagPerformance.startViewLoadSpan(name: "ManualView", viewType: .swiftUI, options:options).end()
    }
}
