//
//  ManualSpanBeforeStartScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 04/10/2022.
//

import BugsnagPerformance

@objcMembers
class ManualSpanBeforeStartScenario: Scenario {
    
    override func startBugsnag() {
        config.appVersion = "42"
        config.bundleVersion = "42.42"
        BugsnagPerformance.startSpan(name: "BeforeStart").end()
        super.startBugsnag()
    }

    override func run() {
    }
}
