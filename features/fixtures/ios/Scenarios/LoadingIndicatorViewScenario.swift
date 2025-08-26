//
//  LoadingIndicatorViewScenario.swift
//  Fixture
//
//  Created by Daria Bialobrzeska on 20/08/2025.
//

import BugsnagPerformance

import UIKit
import os
import os.log

@objcMembers
class LoadingIndicatorViewScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentViewControllers = true
    }

    override func run() {
        let viewController = LoadingIndicatorViewScenario_ViewController()
        UIApplication.shared.windows[0].rootViewController!.present(
            viewController, animated: true)
    }
}

class CustomView : BugsnagPerformanceLoadingIndicatorView {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.backgroundColor = .red

        if #available(iOS 14.0, *) {
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "custom")
            logger.log("[DARIA_LOG] didMoveToSuperview CustomView")
        }
        // Simulate a loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // Put your code which should be executed with a delay here
        }
    }
}

class LoadingIndicatorViewScenario_ViewController: UIViewController {

    override func loadView() {
        view = CustomView()
        view.backgroundColor = .blue
    }
}
