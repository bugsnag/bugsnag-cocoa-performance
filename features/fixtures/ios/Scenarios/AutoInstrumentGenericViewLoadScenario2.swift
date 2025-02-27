//
//  AutoInstrumentGenericViewLoadScenario2.swift
//  Fixture
//
//  Created by Karl Stenerud on 22.11.24.
//

import Foundation

@objcMembers
class AutoInstrumentGenericViewLoadScenario2: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentViewControllers = true
        // This test can generate a variable number of spans depending on the OS version,
        // so use a timed send instead.
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 100
        bugsnagPerfConfig.internal.performWorkInterval = 1
    }

    override func run() {
        let vc = GenericViewController<Int>()
        UIApplication.shared.windows[0].rootViewController!.present(vc, animated: true)
    }
}

class GenericViewController<T>: UIViewController {
    var value: T?

    init() {
        super.init(nibName: nil, bundle: nil)
        value = nil
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        value = nil
    }
}
