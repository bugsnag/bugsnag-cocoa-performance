//
//  AutoInstrumentNavigationViewLoadScenario.swift
//  Fixture
//
//  Created by Robert B on 16/06/2023.
//

import Foundation

import UIKit

@objcMembers
class AutoInstrumentNavigationViewLoadScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.autoInstrumentViewControllers = true
        // This test can generate a variable number of spans depending on the OS version,
        // so use a timed send instead.
        config.internal.autoTriggerExportOnBatchSize = 100
        config.internal.performWorkInterval = 1
    }
    
    override func run() {
        UIApplication.shared.windows[0].rootViewController!.present(
            AutoInstrumentNavigationViewLoadScenario_ViewController(), animated: true)
    }
}

class AutoInstrumentNavigationViewLoadScenario_ViewController: UITabBarController {
    let subVC = AutoInstrumentNavigationViewLoadScenario_SubViewController()

    override func viewDidLoad() {
        viewControllers = [subVC]
    }
}

class AutoInstrumentNavigationViewLoadScenario_SubViewController: UIViewController {
    
    override func loadView() {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        view = label
    }
}
