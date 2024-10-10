//
//  ManualUIViewLoadScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 14.02.23.
//

import BugsnagPerformance

@objcMembers
class ManualUIViewLoadScenario: Scenario {

    override func run() {
        let controller = UIViewController()
        let options = BugsnagPerformanceSpanOptions().setStartTime(Date())
        BugsnagPerformance.startViewLoadSpan(controller: controller, options: options)
        BugsnagPerformance.endViewLoadSpan(controller: controller, endTime: Date())
    }
}
