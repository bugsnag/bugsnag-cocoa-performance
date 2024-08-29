//
//  EarlySpanOnEndScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 15.08.24.
//

import Foundation

@objcMembers
class EarlySpanOnEndScenario: Scenario {

    override func configure() {
        // Early network span
        query(string: "test")

        super.configure()
        config.autoInstrumentAppStarts = true
        config.autoInstrumentNetworkRequests = true
        config.add { span in
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
