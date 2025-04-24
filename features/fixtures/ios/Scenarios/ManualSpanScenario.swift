//
//  ManualSpanScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class ManualSpanScenario: Scenario {

    override func startBugsnag() {
        Bugsnag.start(with: {
            let config = BugsnagConfiguration.loadConfig()
            config.apiKey = "12312312312312312312312312312312"
            config.endpoints.notify = fixtureConfig.notifyURL.absoluteString
            config.endpoints.sessions = fixtureConfig.sessionsURL.absoluteString
            return config
        }())

        super.startBugsnag()
    }

    override func run() {
        let span = BugsnagPerformance.startSpan(name: "ManualSpanScenario")
        Bugsnag.notifyError(NSError(domain: "Test", code: 0))
        span.end()
    }
}
