//
//  AutoInstrumentPreLoadedViewLoadScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 25/01/2024.
//

import Foundation

import UIKit

@objcMembers
class AutoInstrumentPreLoadedViewLoadScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.autoInstrumentViewControllers = true
    }

    override func run() {
        let viewController = AutoInstrumentPreLoadedViewLoadScenario_ViewController()
        _ = viewController.view
        Thread.sleep(forTimeInterval: 1.5)
        UIApplication.shared.windows[0].rootViewController!.present(
            viewController, animated: true)
    }
}

class AutoInstrumentPreLoadedViewLoadScenario_ViewController: UIViewController {
    
    override func loadView() {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        view = label
    }
}
