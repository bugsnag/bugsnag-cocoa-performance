//
//  AutoInstrumentFileURLRequestScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 11.05.23.
//

import Foundation

@objcMembers
class AutoInstrumentFileURLRequestScenario: Scenario {

    override func configure() {
        super.configure()
        config.autoInstrumentNetworkRequests = true
    }

    override func run() {
        // Force the automatic spans to be sent in a separate trace that we will discard
        waitForCurrentBatch()
        let url = URL(string: "file:///x")!
        URLSession.shared.dataTask(with: url).resume()
    }
}
