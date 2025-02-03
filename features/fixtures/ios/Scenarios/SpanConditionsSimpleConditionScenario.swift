//
//  SpanConditionsSimpleConditionScenario.swift
//  Fixture
//
//  Created by Robert B on 31/01/2025.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class SpanConditionsSimpleConditionScenario: Scenario {
    
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
        let span1 = BugsnagPerformance.startSpan(name: "SpanConditionsSimpleConditionScenarioSpan1")
        let condition = span1.block(timeout: 0.5)
        span1.end()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            condition?.upgrade()
            let span2 = BugsnagPerformance.startSpan(name: "SpanConditionsSimpleConditionScenarioSpan2")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                span2.end()
                condition?.close(endTime: Date())
            })
        })
    }
}
