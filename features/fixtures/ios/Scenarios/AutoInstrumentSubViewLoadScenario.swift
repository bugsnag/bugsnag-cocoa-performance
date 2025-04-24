//
//  AutoInstrumentSubViewLoadScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 27.03.23.
//

import UIKit

@objcMembers
class AutoInstrumentSubViewLoadScenario: Scenario {
    
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
            AutoInstrumentSubViewLoadScenario_ViewController(), animated: true)
    }
}

class AutoInstrumentSubViewLoadScenario_ViewController: UIViewController {
    let subVC = AutoInstrumentSubViewLoadScenario_SubViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        add(childViewController:AutoInstrumentSubViewLoadScenario_SubViewController(), to:view)
    }
}

class AutoInstrumentSubViewLoadScenario_SubViewController: UIViewController {
    
    override func loadView() {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.text = String(describing: type(of: self))
        view = label
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension UIViewController {
    func add(childViewController viewController: UIViewController, to contentView: UIView) {
        addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(viewController.view)
        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            viewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        viewController.didMove(toParent: self)
    }
}
