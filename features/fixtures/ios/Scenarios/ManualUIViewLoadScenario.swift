//
//  ManualUIViewLoadScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 14.02.23.
//

import BugsnagPerformance

class ManualUIViewLoadScenario: Scenario {

    override func run() {
        var controller = UIViewController()
        BugsnagPerformance.startViewLoadSpan(controller: controller, startTime: Date())
        BugsnagPerformance.endViewLoadSpan(controller: controller, endTime: Date())
        waitForCurrentBatch()
    }
}
