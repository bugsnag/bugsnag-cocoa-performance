//
//  AutoInstrumentViewLoadScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 12/10/2022.
//

import UIKit

class AutoInstrumentViewLoadScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.autoInstrumentViewControllers = true
    }

    override func run() {
        UIApplication.shared.windows[0].rootViewController!.present(
            AutoInstrumentViewLoadScenario_ViewController(), animated: true)
    }
}

class AutoInstrumentViewLoadScenario_ViewController: UIViewController {
    
    override func loadView() {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        view = label
    }
}
