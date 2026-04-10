//
//  StorageDirectoryScenario.swift
//  Fixture
//
//  Created by Automated Edit on 10.04.26.
//

import Foundation

// Scenario used by features/default/storage_directory.feature.
// Keeps the fixture "neutral": just loads and waits for Maze steps to drive storage behavior.
@objcMembers
class StorageDirectoryScenario: Scenario {
    override func run() {
        logDebug("StorageDirectoryScenario.run(): Ready for storage directory tests")
        logDebug("StorageDirectoryScenario.run(): Done")
    }
}
