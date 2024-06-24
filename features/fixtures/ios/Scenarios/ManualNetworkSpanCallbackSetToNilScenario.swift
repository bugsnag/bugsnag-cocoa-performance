//
//  ManualNetworkSpanCallbackSetToNilScenario.swift
//  Fixture
//
//  Created by Robert B on 21/06/2024.
//

import BugsnagPerformance
import os

class MyCallbackSetToNilNetworkDelegate: NSObject {
    static let shared = MyCallbackSetToNilNetworkDelegate()
    public let urlConfiguration = URLSessionConfiguration.default
    public var urlSession: URLSession!
 
    private override init() {
        super.init()
        self.urlSession = URLSession(configuration: urlConfiguration, delegate: self, delegateQueue: OperationQueue())
    }
}

extension MyCallbackSetToNilNetworkDelegate : URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        BugsnagPerformance.reportNetworkRequestSpan(task: task, metrics: metrics)
    }
}

@objcMembers
class ManualNetworkSpanCallbackSetToNilScenario: Scenario {

    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        MyCallbackSetToNilNetworkDelegate.shared.urlSession.dataTask(with: url).resume()
    }
    
    override func configure() {
        super.configure()
        config.networkRequestCallback = nil
    }

    override func run() {
        query(string: "?status=200")
    }
}
