//
//  CustomPlistPrecedenceScenario.swift
//  Fixture
//
//  Created by automated assistant on 2026-04-01.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class CustomPlistPrecedenceScenario: Scenario {

    override func startBugsnag() {
        // Load the default config then override the apiKey to simulate a custom plist/config value
        Bugsnag.start(with: {
            let config = BugsnagConfiguration.loadConfig()
            // Simulate a "custom" api key as the reviewer expected — this should be visible
            // in the error payload header consumed by the test harness
            config.apiKey = "custom-api-key-0000000000000000000000000000"
            // Keep endpoints from the fixture so the harness can pick them up
            config.endpoints.notify = fixtureConfig.notifyURL.absoluteString
            config.endpoints.sessions = fixtureConfig.sessionsURL.absoluteString
            return config
        }())

        super.startBugsnag()
    }

    override func run() {
        // Start a span and generate an error so the test harness can assert headers/fields
        let span = BugsnagPerformance.startSpan(name: "CustomPlistPrecedenceScenario")
        Bugsnag.notifyError(NSError(domain: "Test", code: 0))
        span.end()
    }
}
