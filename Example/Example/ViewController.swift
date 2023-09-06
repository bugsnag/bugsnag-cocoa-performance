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

    @IBAction func DoNetworkRequest(_ sender: Any) {
        for _ in 1...1000 {
            let url = URL(string: "https://bugsnag.com")!
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            }
            task.resume()
        }
    }

    func doManualSpans() {
        var opts = BugsnagPerformanceSpanOptions()
        opts.setMakeCurrentContext(true)
        
        
        
        //        var arr = [BugsnagPerformanceSpan]()
        //        arr.reserveCapacity(1000)
                let startTime = begin_timed_op()
                for _ in 1...4 {
        //            arr.append(BugsnagPerformance.startSpan(name: "my span"))
                    let span = BugsnagPerformance.startSpan(name: "my span", options: opts)
                    span.end()
                }
                end_timed_op("4 manual nested spans", startTime)

    }
    
    @IBAction func DoManualSpan(_ sender: Any) {
        for _ in 1...1000 {
            doManualSpans()
        }
        Thread.sleep(forTimeInterval: 2)
    }
}
