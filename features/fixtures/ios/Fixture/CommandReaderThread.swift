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

    func receiveNextCommand() {
        let fetchTask = CommandFetchTask(url: fixtureConfig.commandURL)
        fetchTask.start()

        while true {
            switch fetchTask.state {
            case CommandFetchState.success:
                commandReceiver.receiveCommand(command: fetchTask.command!)
                return
            case CommandFetchState.fetching:
                logDebug("Command fetch server hasn't responded yet, waiting 1 second more...")
                Thread.sleep(forTimeInterval: 1)
                break
            case CommandFetchState.failed:
                logInfo("Command fetch request failed. Trying again...")
                Thread.sleep(forTimeInterval: 1)
                fetchTask.start()
                break
            }
        }
    }
}

enum CommandFetchState {
    case failed, fetching, success
}

class CommandFetchTask {
    var url: URL
    var state = CommandFetchState.failed
    var command: MazeRunnerCommand?

    init(url: URL) {
        self.url = url
    }

    func start() {
        logInfo("Fetching next command from \(url)")
        state = CommandFetchState.fetching
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                do {
                    let command = try decoder.decode(MazeRunnerCommand.self, from: data)
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
        task.resume()
    }
}
