//
//  MazeRunnerCommand.swift
//  Fixture
//
//  Created by Karl Stenerud on 16.11.23.
//

import Foundation

class MazeRunnerCommand {
    let message: String
    let action: String
    let uuid: String
    let args: Dictionary<String,Any>
    
    init(uuid: String, action: String, args: Dictionary<String,Any>, message: String) {
        self.uuid = uuid
        self.message = message
        self.action = action
        self.args = args
    }
    
    init(fromJSONDict: Dictionary<String, Any>) {
        self.uuid = fromJSONDict["uuid"] as! String
        self.action = fromJSONDict["action"] as! String
        self.args = fromJSONDict["args"] as! Dictionary<String, Any>
        self.message = fromJSONDict["message"] as? String ?? ""
    }
}
