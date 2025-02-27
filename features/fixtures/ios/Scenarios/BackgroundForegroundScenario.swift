//
//  BackgroundForegroundScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 10.03.23.
//

import BugsnagPerformance

@objcMembers
class BackgroundForegroundScenario: Scenario {
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.internal.autoTriggerExportOnBatchSize = 1
    }
    
    override func run() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            BugsnagPerformance.startSpan(name: "BackgroundForegroundScenario").end()
        }
    }
}
