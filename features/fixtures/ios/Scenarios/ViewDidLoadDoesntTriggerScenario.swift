//
//  ViewDidLoadDoesntTriggerScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 21.03.24.
//

import UIKit

@objcMembers
class ViewDidLoadDoesntTriggerScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentViewControllers = true
    }

    override func run() {
        let vc = ViewDidLoadDoesntTriggerScenario_ViewController()
        
        // Simulate showing a view, except that viewDidAppear doesn't trigger
        vc.loadView()
        vc.viewDidLoad()
        vc.viewWillAppear(false)
        vc.viewWillLayoutSubviews()
        vc.viewDidLayoutSubviews()
    }
}

class ViewDidLoadDoesntTriggerScenario_ViewController: UIViewController {
    
    override func loadView() {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        view = label
    }
}
