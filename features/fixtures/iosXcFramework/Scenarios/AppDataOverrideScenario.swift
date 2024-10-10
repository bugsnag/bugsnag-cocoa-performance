//
//  AppDataOverrideScenario.swift
//  Fixture
//
//  Created by Robert B on 16/08/2024.
//

import BugsnagPerformance

@objcMembers
class AppDataOverrideScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.serviceName = "com.bugsnag.AppDataOverrideScenario"
        config.bundleVersion = "100"
        config.appVersion = "42.0"
    }
    
    override func run() {
        let span = BugsnagPerformance.startSpan(name: "AppDataOverrideScenario")
        span.end()
    }
}
