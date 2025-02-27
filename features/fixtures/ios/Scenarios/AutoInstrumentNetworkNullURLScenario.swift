//
//  AutoInstrumentNetworkNullURLScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 12.03.24.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkNullURLScenario: Scenario {

    override func postLoad() {
        super.postLoad()
        // Early phase span. Make sure it doesn't crash or generate a span
        ObjCURLSession.dataTask(with: nil).resume()
    }

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentNetworkRequests = true
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        URLSession.shared.dataTask(with: url).resume()
    }

    override func run() {
        // Force the automatic spans to be sent in a separate trace that we will discard
        waitForCurrentBatch()
        // Send an actual request to be captured
        query(string: "?status=200")
    }
}
