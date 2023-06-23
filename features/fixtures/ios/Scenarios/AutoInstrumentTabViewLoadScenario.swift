//
//  AutoInstrumentTabViewLoadScenario.swift
//  Fixture
//
//  Created by Robert B on 16/06/2023.
//

import Foundation

import UIKit

@objcMembers
class AutoInstrumentTabViewLoadScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.autoInstrumentViewControllers = true
    }
    
    override func run() {
        UIApplication.shared.windows[0].rootViewController!.present(
            AutoInstrumentTabViewLoadScenario_ViewController(), animated: true)
    }
}

class AutoInstrumentTabViewLoadScenario_ViewController: UITabBarController {
    let subVC = AutoInstrumentTabViewLoadScenario_SubViewController()

    override func viewDidLoad() {
        viewControllers = [subVC]
    }
}

class AutoInstrumentTabViewLoadScenario_SubViewController: UIViewController {
    
    override func loadView() {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        view = label
    }
}
