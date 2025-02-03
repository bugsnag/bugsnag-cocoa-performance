//
//  SpanConditionsMultipleConditionsScenario.swift
//  Fixture
//
//  Created by Robert B on 31/01/2025.
//

import Bugsnag
import BugsnagPerformance

@objcMembers
class SpanConditionsMultipleConditionsScenario: Scenario {
    
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
        let span1 = BugsnagPerformance.startSpan(name: "SpanConditionsMultipleConditionsScenarioSpan1")
        let condition1 = span1.block(timeout: 0.5)
        let condition2 = span1.block(timeout: 0.5)
        let condition3 = span1.block(timeout: 0.5)
        span1.end()
        condition3?.upgrade()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            condition1?.cancel()
            condition2?.upgrade()
            let span2 = BugsnagPerformance.startSpan(name: "SpanConditionsMultipleConditionsScenarioSpan2")
            let span3 = BugsnagPerformance.startSpan(name: "SpanConditionsMultipleConditionsScenarioSpan3")
            let condition4 = span3.block(timeout: 1)
            condition3?.close(endTime: Date())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                span3.end()
                condition4?.upgrade()
                span2.end()
                condition4?.close(endTime: Date())
                condition2?.close(endTime: Date())
            })
        })
    }
}
