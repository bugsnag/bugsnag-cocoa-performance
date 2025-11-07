//
//  CommandReaderThread.swift
//  iOSTestApp
//
//  Created by Karl Stenerud on 16.11.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

import UIKit
import os

class CommandReaderThread: Thread {
    var fixtureConfig: FixtureConfig
    var commandReceiver: CommandReceiver
    var lastCommandID: String = ""

    init(fixtureConfig: FixtureConfig, commandReceiver: CommandReceiver) {
        self.fixtureConfig = fixtureConfig
        self.commandReceiver = commandReceiver
    }

    override func main() {
        while true {
            if self.commandReceiver.canReceiveCommand() {
                receiveNextCommand()
            } else {
                logDebug("A command is already in progress, waiting 1 second more...")
            }
            Thread.sleep(forTimeInterval: 1)
        }
    }

    func newStartedFetchTask() -> CommandFetchTask {
        let fetchTask = CommandFetchTask(url: fixtureConfig.commandURL, afterCommandID: lastCommandID)
        fetchTask.start()
        return fetchTask
    }

    func receiveNextCommand() {
        let maxWaitTime = 5.0
        let pollingInterval = 1.0

        var fetchTask = newStartedFetchTask()
        let startTime = Date()

        while true {
            Thread.sleep(forTimeInterval: pollingInterval)
            switch fetchTask.state {
            case CommandFetchState.success:
                logDebug("Command fetch: Request succeeded")
                let command = fetchTask.command!
                if (command.action == "reset_uuid") {
                    logDebug("Resetting last command UUID to empty string")
                    lastCommandID = ""
                } else {
                    logDebug("Last command UUID is now: \(command.uuid)")
                    lastCommandID = command.uuid
                }
                commandReceiver.receiveCommand(command: command)
                return
            case CommandFetchState.fetching:
                let duration = Date() - startTime
                if duration < maxWaitTime {
                    logDebug("Command fetch: Server hasn't responded in \(duration)s (max \(maxWaitTime)). Waiting \(pollingInterval)s more...")
                } else {
                    fetchTask.cancel()
                    logInfo("Command fetch: Server hasn't responded in \(duration)s (max \(maxWaitTime)). Trying again...")
                    fetchTask = newStartedFetchTask()
                }
                break
            case CommandFetchState.failed:
                logInfo("Command fetch: Request failed. Trying again...")
                fetchTask = newStartedFetchTask()
                break
            }
        }
    }
}

extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}

enum CommandFetchState {
    case failed, fetching, success
}

class CommandFetchTask {
    var url: URL
    var state = CommandFetchState.failed
    var command: MazeRunnerCommand?
    var task: URLSessionTask?

    init(url: URL, afterCommandID: String) {
        self.url = URL(string: "\(url.absoluteString)?after=\(afterCommandID)")!
    }

    func cancel() {
        task?.cancel()
    }

    func start() {
        logInfo("Fetching next command from \(url)")
        state = CommandFetchState.fetching
        let request = URLRequest(url: url)
        task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let asString = String(data: data, encoding: .utf8)!
                    logInfo("Received command:\n\(asString)")
                    let decoded = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    let command = MazeRunnerCommand.init(fromJSONDict: decoded)
                    logInfo("Command fetched and decoded")
                    self.command = command;
                    self.state = CommandFetchState.success
                } catch {
                    self.state = CommandFetchState.failed
                    let dataAsString = String(data: data, encoding: .utf8)
                    logError("Failed to fetch command: Invalid Response from \(String(describing: self.url)): [\(String(describing: dataAsString))]: Error is: \(error)")
                }
            } else if let error = error {
                self.state = CommandFetchState.failed
                logError("Failed to fetch command: HTTP Request to \(String(describing: self.url)) failed: \(error)")
            }
        }
        task?.resume()
    }
}
