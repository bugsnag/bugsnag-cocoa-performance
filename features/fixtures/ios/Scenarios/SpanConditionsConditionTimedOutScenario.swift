//
//  SpanConditionsConditionTimedOutScenario.swift
//  Fixture
//
//  Created by Robert B on 31/01/2025.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class SpanConditionsConditionTimedOutScenario: Scenario {
    
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
        let span1 = BugsnagPerformance.startSpan(name: "SpanConditionsConditionTimedOutScenarioSpan1")
        span1.block(timeout: 0.7)
        span1.end()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            let span2 = BugsnagPerformance.startSpan(name: "SpanConditionsConditionTimedOutScenarioSpan2")
            span2.end()
        })
    }
}
