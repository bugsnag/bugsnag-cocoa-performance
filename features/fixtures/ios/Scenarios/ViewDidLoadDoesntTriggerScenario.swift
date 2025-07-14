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
        let keepViewControllerAlive = toBool(string: scenarioConfig["keep_view_controller_alive"])
        let vc = ViewDidLoadDoesntTriggerScenario_ViewController()
        
        // Simulate showing a view, except that viewDidAppear doesn't trigger
        vc.loadView()
        vc.viewDidLoad()
        vc.viewWillAppear(false)
        vc.viewWillLayoutSubviews()
        vc.viewDidLayoutSubviews()
        let endOnDeinitSpan = BugsnagPerformance.startSpan(name: "ViewDidLoadDoesntTriggerScenarioOnDeinitSpan")
        vc.endOnDeinitSpan = endOnDeinitSpan
        
        if keepViewControllerAlive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 500) {
                // Will never be excecuted becaouse of the timeout. This is only to keep the view controller alive with a strong reference
                NSLog("\(vc.children)")
            }
        }
    }
}

class ViewDidLoadDoesntTriggerScenario_ViewController: UIViewController {
    
    var endOnDeinitSpan: BugsnagPerformanceSpan?
    
    override func loadView() {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        view = label
    }
    
    deinit {
        endOnDeinitSpan?.end()
    }
}
