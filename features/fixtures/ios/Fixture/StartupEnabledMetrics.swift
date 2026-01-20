//
//  StartupEnabledMetrics.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 29/10/2025.
//

import Foundation

class StartupEnabledMetrics: Codable {

    public var rendering: Bool
    public var cpu: Bool
    public var memory: Bool

    init() {
        self.rendering = false
        self.cpu = false
        self.memory = false
    }
}
