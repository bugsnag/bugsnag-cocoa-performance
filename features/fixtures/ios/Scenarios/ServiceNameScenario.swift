//
//  ServiceNameScenario.swift
//  Fixture
//
//  Created by Robert B on 16/08/2024.
//

import BugsnagPerformance

@objcMembers
class ServiceNameScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.serviceName = "com.bugsnag.ServiceNameScenario"
    }
    
    override func run() {
        let span = BugsnagPerformance.startSpan(name: "ServiceNameScenario")
        span.end()
    }
}
