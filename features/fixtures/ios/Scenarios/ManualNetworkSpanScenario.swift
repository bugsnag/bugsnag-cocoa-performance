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

    lazy var baseURL: URL = {
        var components = URLComponents(string: Scenario.mazeRunnerURL)!
        components.port = 9340 // `/reflect` listens on a different port :-((
        return components.url!
    }()

    func query(string: String) {
        let url = URL(string: string, relativeTo: baseURL)!
        MyNetworkDelegate.shared.urlSession.dataTask(with: url).resume()
    }

    override func run() {
        query(string: "/reflect/?status=200")
    }
}
