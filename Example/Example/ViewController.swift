//
//  ViewController.swift
//  Example
//
//  Created by Nick Dowell on 21/09/2022.
//

import UIKit
import SwiftUI
import BugsnagPerformance

class ViewController: UIViewController {

    @IBAction func showSwiftUIView(_ sender: Any) {
        if #available(iOS 13.0.0, *) {
            show(UIHostingController(rootView: SomeView()), sender: sender)
        } else {
            present(UIAlertController(
                title: "Error",
                message: "SwiftUI is not available on this version of iOS",
                preferredStyle: .alert), animated: true)
        }
    }

    func query(string: String) {
        let url = URL(string: "https://bugsnag.com")!
        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        Thread.sleep(forTimeInterval: 1)
    }

    @IBAction func DoNetworkRequest(_ sender: Any) {
        query(string: "x")
    }

    @IBAction func DoManualSpan(_ sender: Any) {
        let span = BugsnagPerformance.startSpan(name: "my span")
        // Wait between 100ms and 1s
        let waitTime = arc4random() % 900000
        usleep(100000 + waitTime)
        span.end()
    }
}
