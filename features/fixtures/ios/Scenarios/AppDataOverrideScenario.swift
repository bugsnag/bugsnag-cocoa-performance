//
//  AppDataOverrideScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 16/08/2024.
//

import BugsnagPerformance

@objcMembers
class AppDataOverrideScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.serviceName = "com.bugsnag.AppDataOverrideScenario"
        bugsnagPerfConfig.bundleVersion = "100"
        bugsnagPerfConfig.appVersion = "42.0"
    }
    
    override func run() {
        let span = BugsnagPerformance.startSpan(name: "AppDataOverrideScenario")
        span.end()
    }
}
