//
//  ManualSpanBeforeStartScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 04/10/2022.
//

import BugsnagPerformance

@objcMembers
class ManualSpanBeforeStartScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.appVersion = "42"
        bugsnagPerfConfig.bundleVersion = "42.42"
    }

    override func postLoad() {
        super.postLoad()
        BugsnagPerformance.startSpan(name: "BeforeStart").end()
    }

    override func run() {
    }
}
