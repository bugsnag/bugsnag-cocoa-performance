//
//  ModifyEarlySpansScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 29.08.24.
//

import BugsnagPerformance

@objcMembers
class ModifyEarlySpansScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.autoInstrumentAppStarts = true
        config.autoInstrumentNetworkRequests = true
        config.add(onSpanEndCallback: { (span: BugsnagPerformanceSpan) -> Bool in
            span.setAttribute("modifiedOnEnd", withValue: "yes")
            return true
        })

        query(string: "?status=200")
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        URLSession.shared.dataTask(with: url).resume()
    }

    override func run() {
    }
}
