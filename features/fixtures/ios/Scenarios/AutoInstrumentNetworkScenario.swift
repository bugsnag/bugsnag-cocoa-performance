//
//  AutoInstrumentNetworkScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 20.10.22.
//

import Foundation

class AutoInstrumentNetworkScenario: Scenario {

    lazy var baseURL: URL = {
        var components = URLComponents(string: Scenario.mazeRunnerURL.absoluteString)!
        components.port = 9340 // `/reflect` listens on a different port :-((
        return components.url!
    }()

    override func startBugsnag() {
        config.autoInstrumentNetwork = true
        super.startBugsnag()
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: baseURL)!
        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        Thread.sleep(forTimeInterval: 1)
    }

    override func run() {
        query(string: "/reflect/?status=200")
    }
}
