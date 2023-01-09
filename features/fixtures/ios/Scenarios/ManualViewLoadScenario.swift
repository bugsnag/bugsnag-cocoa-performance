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
        BugsnagPerformance.startViewLoadSpan(name: "ManualView", viewType: .swiftUI, startTime: Date()).end()
    }
}
