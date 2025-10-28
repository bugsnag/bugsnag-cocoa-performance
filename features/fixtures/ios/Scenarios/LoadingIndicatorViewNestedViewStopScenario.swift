//
//  LoadingIndicatorViewNestedViewStopScenario.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 27/08/2025.
//

import BugsnagPerformance

import UIKit

@objcMembers
class LoadingIndicatorViewNestedViewStopScenario: Scenario {
    
    var viewController: LoadingIndicatorViewNestedViewStopScenario_ParentViewController!

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 1
        bugsnagPerfConfig.autoInstrumentViewControllers = true
    }
    
    func finishLoadingParentInner() {
        viewController.finishLoading1()
    }
    
    func finishLoadingParentOuter() {
        viewController.finishLoading2()
    }
    
    func finishLoadingChild() {
        viewController.finishLoadingChild()
    }

    override func run() {
        viewController = LoadingIndicatorViewNestedViewStopScenario_ParentViewController()
        UIApplication.shared.windows[0].rootViewController!.present(
            viewController, animated: true)
    }
}

class LoadingIndicatorViewNestedViewStopScenario_ParentViewController: UIViewController {
    
    var loadingIndicator1: BugsnagPerformanceLoadingIndicatorView!
    var loadingIndicator2: BugsnagPerformanceLoadingIndicatorView!
    var innerViewController: LoadingIndicatorViewNestedViewStopScenario_ChildViewController!

    override func loadView() {
        loadingIndicator1 = BugsnagPerformanceLoadingIndicatorView()
        loadingIndicator2 = BugsnagPerformanceLoadingIndicatorView()
        let mainView = UIView()
        mainView.addSubview(loadingIndicator1)
        let subview = UIView()
        loadingIndicator1.addSubview(subview)
        subview.addSubview(loadingIndicator2)
        innerViewController = LoadingIndicatorViewNestedViewStopScenario_ChildViewController()
        addChild(innerViewController)
        subview.addSubview(innerViewController.view)
        view = mainView
    }
    
    func finishLoading1() {
        loadingIndicator1.finishLoading()
    }
    
    func finishLoading2() {
        loadingIndicator2.finishLoading()
    }
    
    func finishLoadingChild() {
        innerViewController.loadingIndicator.finishLoading()
    }
}

class LoadingIndicatorViewNestedViewStopScenario_ChildViewController: UIViewController {
    
    var loadingIndicator: BugsnagPerformanceLoadingIndicatorView!

    override func loadView() {
        loadingIndicator = BugsnagPerformanceLoadingIndicatorView()
        view = UIView()
        view.addSubview(loadingIndicator)
    }
    
    func finishLoading() {
        loadingIndicator.finishLoading()
    }
}
