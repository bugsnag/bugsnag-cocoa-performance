//
//  ManualNetworkSpanCallbackNotSetScenario.swift
//  Fixture
//
//  Created by Robert B on 21/06/2024.
//

import BugsnagPerformance
import os

class MyCallbackNotSetNetworkDelegate: NSObject {
    static let shared = MyCallbackNotSetNetworkDelegate()
    public let urlConfiguration = URLSessionConfiguration.default
    public var urlSession: URLSession!
 
    private override init() {
        super.init()
        self.urlSession = URLSession(configuration: urlConfiguration, delegate: self, delegateQueue: OperationQueue())
    }
}

extension MyCallbackNotSetNetworkDelegate : URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        BugsnagPerformance.reportNetworkRequestSpan(task: task, metrics: metrics)
    }
}

@objcMembers
class ManualNetworkSpanCallbackNotSetScenario: Scenario {

    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        MyCallbackNotSetNetworkDelegate.shared.urlSession.dataTask(with: url).resume()
    }
    
    override func configure() {
        super.configure()
        config.networkRequestCallback = nil
    }

    override func run() {
        query(string: "?status=200")
    }
}
