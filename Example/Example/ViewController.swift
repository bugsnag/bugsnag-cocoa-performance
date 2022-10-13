//
//  ViewController.swift
//  Example
//
//  Created by Nick Dowell on 21/09/2022.
//

import UIKit
import SwiftUI

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
}
