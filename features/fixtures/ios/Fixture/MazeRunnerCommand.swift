//
//  MazeRunnerCommand.swift
//  Fixture
//
//  Created by Karl Stenerud on 16.11.23.
//

import Foundation

class MazeRunnerCommand: Codable {
    let message: String
    let action: String
    let args: Array<String>
    
    init(action: String, args: Array<String>, message: String) {
        self.message = message
        self.action = action
        self.args = args
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        self.action = try container.decodeIfPresent(String.self, forKey: .action) ?? ""
        self.args = try container.decodeIfPresent(Array<String>.self, forKey: .args) ?? []
    }
}
