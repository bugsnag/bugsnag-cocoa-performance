//
//  EarlySpanOnEndScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 15.08.24.
//

import Foundation

@objcMembers
class EarlySpanOnEndScenario: Scenario {

    override func postLoad() {
        super.postLoad()
        // Early network span
        query(string: "test")
    }

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentAppStarts = true
        bugsnagPerfConfig.autoInstrumentNetworkRequests = true
        bugsnagPerfConfig.add { span in
            // We've turned on app start spans, but they'll get filtered
            // out here because they don't contain "HTTP" in their names.
            return span.name.contains("HTTP")
        }
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        URLSession.shared.dataTask(with: url).resume()
    }

    override func run() {
    }
}
