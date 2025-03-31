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
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentViewControllers = true
        // This test can generate a variable number of spans depending on the OS version,
        // so use a timed send instead.
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
        bugsnagPerfConfig.internal.performWorkInterval = 1
    }

    override func run() {
        UIApplication.shared.windows[0].rootViewController!.present(
            AutoInstrumentGenericViewLoadScenario_ViewController<AutoInstrumentGenericViewLoadScenario_GenericsClass>().bugsnagTraced(), animated: true)
    }
}

class AutoInstrumentGenericViewLoadScenario_ViewController<T: AutoInstrumentGenericViewLoadScenario_GenericsBaseProtocol>: UIViewController {
    
    override func loadView() {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        view = label
    }
}

class TestViewController: AutoInstrumentGenericViewLoadScenario_ViewController<AutoInstrumentGenericViewLoadScenario_GenericsClass> {
    
}
