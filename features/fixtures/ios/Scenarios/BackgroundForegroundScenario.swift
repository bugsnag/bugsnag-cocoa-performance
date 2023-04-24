//
//  BackgroundForegroundScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 10.03.23.
//

import BugsnagPerformance

class BackgroundForegroundScenario: Scenario {
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid

    override func configure() {
        super.configure()
        config.internal.autoTriggerExportOnBatchSize = 100
        config.internal.performWorkInterval = 1000
    }
    
    func onBackgrounded() {
        BugsnagPerformance.startSpan(name: "BackgroundForegroundScenario").end()
    }

    override func run() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            BugsnagPerformance.startSpan(name: "BackgroundForegroundScenario").end()
        }
    }
}
