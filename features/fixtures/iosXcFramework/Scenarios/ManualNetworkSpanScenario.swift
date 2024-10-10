//
//  ManualNetworkSpan.swift
//  Fixture
//
//  Created by Karl Stenerud on 17.10.22.
//

import BugsnagPerformance
import os

class MyNetworkDelegate: NSObject {
    static let shared = MyNetworkDelegate()
    public let urlConfiguration = URLSessionConfiguration.default
    public var urlSession: URLSession!
 
    private override init() {
        super.init()
        self.urlSession = URLSession(configuration: urlConfiguration, delegate: self, delegateQueue: OperationQueue())
    }
}

extension MyNetworkDelegate : URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        BugsnagPerformance.reportNetworkRequestSpan(task: task, metrics: metrics)
    }
}

@objcMembers
class ManualNetworkSpanScenario: Scenario {

    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        MyNetworkDelegate.shared.urlSession.dataTask(with: url).resume()
    }

    override func run() {
        query(string: "?status=200")
    }
}
