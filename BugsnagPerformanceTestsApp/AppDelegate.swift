//
//  AppDelegate.swift
//  BugsnagPerformanceTestsApp
//
//  Created by Robert B on 12/04/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

import UIKit
import BugsnagPerformance

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        BugsnagPerformance.start(withApiKey: "1234")
        return true
    }
}

