//
//  LoadingIndicatorViewSimpleStopScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 27/08/2025.
//

import BugsnagPerformance

import UIKit

@objcMembers
class LoadingIndicatorViewSimpleStopScenario: Scenario {
    
    var viewController: LoadingIndicatorViewSimpleStopScenario_ViewController?

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 1
        bugsnagPerfConfig.autoInstrumentViewControllers = true
    }
    
    func finishLoading() {
        viewController?.finishLoading()
    }

    override func run() {
        viewController = LoadingIndicatorViewSimpleStopScenario_ViewController()
        UIApplication.shared.windows[0].rootViewController!.present(
            viewController!, animated: true)
    }
}

class LoadingIndicatorViewSimpleStopScenario_ViewController: UIViewController {
    
    var loadingIndicator: BugsnagPerformanceLoadingIndicatorView!

    override func loadView() {
        loadingIndicator = BugsnagPerformanceLoadingIndicatorView()
        view = loadingIndicator
    }
    
    func finishLoading() {
        loadingIndicator.finishLoading()
    }
}
