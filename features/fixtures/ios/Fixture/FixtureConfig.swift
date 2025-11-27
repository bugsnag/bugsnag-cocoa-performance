//
//  FixtureConfig.swift
//  Fixture
//
//  Created by Karl Stenerud on 20.11.23.
//

import Foundation

class FixtureConfig {
    // Base MazeRunner URL
    let mazeRunnerURL: URL

    // Admin URLs we normally don't want to capture
    let docsURL: URL
    let tracesURL: URL
    let commandURL: URL
    let metricsURL: URL
    let notifyURL: URL
    let sessionsURL: URL

    // URLs explicitly used in tests
    let reflectURL: URL

    // Convenience URL sets
    let adminMazeRunnerURLs: [URL]
    let allMazeRunnerURLs: [URL]

    init(mazeRunnerBaseAddress: URL) {
        mazeRunnerURL = mazeRunnerBaseAddress

        docsURL = mazeRunnerBaseAddress.appendingPathComponent("docs")
        tracesURL = mazeRunnerBaseAddress.appendingPathComponent("traces")
        commandURL = mazeRunnerBaseAddress.appendingPathComponent("idem-command")
        metricsURL = mazeRunnerBaseAddress.appendingPathComponent("metrics")
        notifyURL = mazeRunnerBaseAddress.appendingPathComponent("notify")
        sessionsURL = mazeRunnerBaseAddress.appendingPathComponent("sessions")

        reflectURL = mazeRunnerBaseAddress.appendingPathComponent("reflect")

        adminMazeRunnerURLs = [
            docsURL,
            tracesURL,
            commandURL,
            metricsURL,
            notifyURL,
            sessionsURL,
        ]
        allMazeRunnerURLs = [mazeRunnerURL]
    }
}
