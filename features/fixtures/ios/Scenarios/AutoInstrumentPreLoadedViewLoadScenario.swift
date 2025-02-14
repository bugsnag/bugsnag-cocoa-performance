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
        // This test can generate a variable number of spans depending on the OS version,
        // so use a timed send instead.
        config.internal.autoTriggerExportOnBatchSize = 100
        config.internal.performWorkInterval = 1
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
        let containerView = UIView()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        containerView.addSubview(label)
        view = containerView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let viewController = AutoInstrumentPreLoadedViewLoadScenario_SubViewController()
        add(childViewController: viewController, to: view)
    }
}

class AutoInstrumentPreLoadedViewLoadScenario_SubViewController: UIViewController {
    
    override func loadView() {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        view = label
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let span = BugsnagPerformance.startSpan(name: "SubViewController_ChildSpan")
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.1)
            span.end()
        }
    }
}
