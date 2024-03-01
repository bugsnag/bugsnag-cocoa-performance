//
//  AutoInstrumentGenericViewLoadScenario.swift
//  Fixture
//
//  Created by Robert B on 07/12/2023.
//

import UIKit

protocol AutoInstrumentGenericViewLoadScenario_GenericsBaseProtocol {
    
}

class AutoInstrumentGenericViewLoadScenario_GenericsClass: AutoInstrumentGenericViewLoadScenario_GenericsBaseProtocol {
    
}

@objcMembers
class AutoInstrumentGenericViewLoadScenario: Scenario {
    
    override func configure() {
        super.configure()
        config.autoInstrumentViewControllers = true
    }

    override func run() {
        UIApplication.shared.windows[0].rootViewController!.present(
            AutoInstrumentGenericViewLoadScenario_ViewController<AutoInstrumentGenericViewLoadScenario_GenericsClass>().bugsnagTraced(), animated: true)
    }
}

@objc class AutoInstrumentGenericViewLoadScenario_ViewController<T: AutoInstrumentGenericViewLoadScenario_GenericsBaseProtocol>: UIViewController {
    
    override func loadView() {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        view = label
    }
}

@objc class TestViewController: AutoInstrumentGenericViewLoadScenario_ViewController<AutoInstrumentGenericViewLoadScenario_GenericsClass> {
    
}
