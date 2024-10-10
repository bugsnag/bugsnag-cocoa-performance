//
//  InfraCheckNoBugsnagScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 02.10.24.
//

import Foundation

// Scenario for testing the infrastructure with NO Bugsnag involvement.
@objcMembers
class InfraCheckNoBugsnagScenario: Scenario {
    override func configure() {
        logDebug("InfraCheckNoBugsnagScenario.configure(): Doing nothing")
    }

    override func startBugsnag() {
        logDebug("InfraCheckNoBugsnagScenario.startBugsnag(): Doing nothing")
    }

    override func run() {
        logDebug("InfraCheckNoBugsnagScenario.run(): Calling reflect URL")
        callReflectUrl(appendingToUrl: "?status=200")
        logDebug("InfraCheckNoBugsnagScenario.run(): Done")
    }
}
