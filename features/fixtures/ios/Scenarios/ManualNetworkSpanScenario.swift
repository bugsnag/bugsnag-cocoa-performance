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
    public var urlSession: URLSession?
 
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

class ManualNetworkSpanScenario: Scenario {

    lazy var baseURL: URL = {
        var components = URLComponents(string: Scenario.mazeRunnerURL.absoluteString)!
        components.port = 9340 // `/reflect` listens on a different port :-((
        return components.url!
    }()

    func query(string: String) {
        let url = URL(string: string, relativeTo: baseURL)!
        let semaphore = DispatchSemaphore(value: 0)

        let task = MyNetworkDelegate.shared.urlSession?.dataTask(with: url) {(data, response, error) in
            semaphore.signal()
        }
        task?.resume()
        semaphore.wait()
    }

    override func run() {
        query(string: "/reflect/?status=200")
    }
}
