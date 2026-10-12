//
//  AutoInstrumentNetworkEarlyCallbackScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 09/12/2025.
//

import Foundation

@objcMembers
class AutoInstrumentNetworkEarlyCallbackScenario: Scenario {
    
    override func postLoad() {
        super.postLoad()
        query(url: URL(string: "https://bugsnag.com")!)
        query(url: URL(string: "https://bugsnag.com/changeme")!)
        query(url: URL(string: "https://google.com")!)
        
        // Wait for the query to finish before starting bugsnag
        Thread.sleep(forTimeInterval: 2.0)
    }

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentNetworkRequests = true
        bugsnagPerfConfig.networkRequestCallback = { (origInfo: BugsnagPerformanceNetworkRequestInfo) -> BugsnagPerformanceNetworkRequestInfo in
            let info = self.filterAdminMazeRunnerNetRequests(info: origInfo)

            let testUrl = info.url
            if (testUrl == nil) {
                return info
            }

            let url = testUrl!

            if url.absoluteString == "https://google.com" {
                info.url = nil
            } else if url.lastPathComponent == "changeme" {
                info.url = URL(string:"changed", relativeTo:url.deletingLastPathComponent())
            }

            return info
        }
    }

    func query(url: URL) {
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
        }
        task.resume()

    }

    override func run() {
    }
}
