//
//  AutoInstrumentNetworkMultiple.swift
//  Fixture
//
//  Created by Karl Stenerud on 23.06.23.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkMultiple: Scenario {

    lazy var baseURL: URL = {
        var components = URLComponents(string: Scenario.mazeRunnerURL)!
        components.port = 9340 // `/reflect` listens on a different port :-((
        return components.url!
    }()

    override func configure() {
        super.configure()
        config.autoInstrumentNetworkRequests = true
    }

    func query(url: String) {
        let url = URL(string: "https://google.com")!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
        }
        task.resume()

    }

    override func run() {
        // Force the automatic spans to be sent in a separate trace that we will discard
        waitForCurrentBatch()
        query(url: "https://google.com")
        query(url: "https://facebook.com")
        query(url: "https://amazon.com")
        query(url: "https://bing.com")
        query(url: "https://reuters.com")
        query(url: "https://sap.com")
        query(url: "https://redhat.com")
        query(url: "https://ubuntu.com")
        query(url: "https://kubernetes.io")
        query(url: "https://bugsnag.com")
    }
}
