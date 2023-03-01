//
//  ManualViewLoadScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 10/10/2022.
//

import BugsnagPerformance

class ManualViewLoadScenario: Scenario {
    
    override func run() {
        BugsnagPerformance.startViewLoadSpan(name: "ManualViewController", viewType: .uiKit).end()
        waitForCurrentBatch()
        let options = BugsnagPerformanceSpanOptions()
        options.startTime = Date()
        BugsnagPerformance.startViewLoadSpan(name: "ManualView", viewType: .swiftUI, options:options).end()
    }
}
