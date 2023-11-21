//
//  FixtureConfig.swift
//  Fixture
//
//  Created by Karl Stenerud on 20.11.23.
//

import Foundation

class FixtureConfig {
    let mazeRunnerURL: URL
    let tracesURL: URL
    let commandURL: URL
    let metricsURL: URL
    let reflectURL: URL
    let notifyURL: URL
    let sessionsURL: URL

    init(mazeRunnerBaseAddress: URL) {
        mazeRunnerURL = mazeRunnerBaseAddress
        tracesURL = mazeRunnerBaseAddress.appendingPathComponent("traces")
        commandURL = mazeRunnerBaseAddress.appendingPathComponent("command")
        metricsURL = mazeRunnerBaseAddress.appendingPathComponent("metrics")
        notifyURL = mazeRunnerBaseAddress.appendingPathComponent("notify")
        sessionsURL = mazeRunnerBaseAddress.appendingPathComponent("sessions")
        reflectURL = mazeRunnerBaseAddress.appendingPathComponent("reflect")
    }
}
