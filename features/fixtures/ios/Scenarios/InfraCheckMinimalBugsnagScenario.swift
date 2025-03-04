//
//  InfraCheckMinimalBugsnagScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 02.10.24.
//

import Foundation

// Scenario for testing the infrastructure with minimal Bugsnag involvement.
@objcMembers
class InfraCheckMinimalBugsnagScenario: Scenario {
    override func run() {
        logDebug("InfraCheckMinimalBugsnagScenario.run(): Calling reflect URL")
        callReflectUrl(appendingToUrl: "?status=208")
        logDebug("InfraCheckMinimalBugsnagScenario.run(): Opening and closing a basic span")
        BugsnagPerformance.startSpan(name: "test").end()
        logDebug("InfraCheckMinimalBugsnagScenario.run(): Done")
    }
}
