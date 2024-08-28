//
//  AutoInstrumentViewLoadScenario.swift
//  Fixture
//
//  Created by Nick Dowell on 12/10/2022.
//

import UIKit

@objcMembers
class AutoInstrumentViewLoadScenario: Scenario {
    
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
