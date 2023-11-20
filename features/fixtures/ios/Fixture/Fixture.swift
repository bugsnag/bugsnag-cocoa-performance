//
//  Fixture.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import Foundation

protocol CommandReceiver {
    func canReceiveCommand() -> Bool
    func receiveCommand(command: MazeRunnerCommand)
}

class Fixture: NSObject, CommandReceiver {
    static let defaultMazeRunnerURL = "http://bs-local.com:9339"
    static let mazeRunnerURL = loadMazeRunnerAddress()
    static let tracesURL = "\(mazeRunnerURL)/traces"
    static let commandURL = "\(mazeRunnerURL)/command"
    static let metricsURL = "\(mazeRunnerURL)/metrics"
    static let reflectURL: String = {
        var components = URLComponents(string: "\(mazeRunnerURL)/reflect")!
        components.port = 9340 // `/reflect` listens on a different port :-((
        return components.url!.absoluteString
    }()

    var readyToReceiveCommand = false

    var commandReaderThread: CommandReaderThread?

    var scenario: Scenario? = nil

    func start() {
        readyToReceiveCommand = true
        let url = URL(string:Fixture.commandURL)!
        commandReaderThread = CommandReaderThread(commandProviderUrl: url, commandReceiver: self)
        commandReaderThread!.start()
    }

    static func isMazeRunnerAdministrationURL(url: URL) -> Bool {
        switch url.absoluteString {
        case tracesURL, commandURL, metricsURL:
            return true
        case reflectURL:
            return false // reflectURL is fair game!
        default:
            return false
        }
    }

    func canReceiveCommand() -> Bool {
        return readyToReceiveCommand
    }

    func receiveCommand(command: MazeRunnerCommand) {
        readyToReceiveCommand = false

        DispatchQueue.main.async {
            logInfo("Executing command [\(command.action)] with args \(command.args)")
            switch command.action {
            case "run_scenario":
                self.runScenario(scenarioName: command.args[0])
                break
            case "invoke_method":
                self.invokeMethod(methodName: command.args[0], args: Array(command.args[1...]))
                break
            case "noop":
                break
            default:
                assertionFailure("\(command.action): Unknown command")
            }
            self.readyToReceiveCommand = true
        }
    }

    private func runScenario(scenarioName: String) {
        logInfo("========== Running scenario \(scenarioName) ==========")
        let scenarioClass: AnyClass = NSClassFromString("Fixture.\(scenarioName)")!
        logInfo("Loaded scenario class: \(scenarioClass)")
        scenario = (scenarioClass as! NSObject.Type).init() as! Scenario?
        logInfo("Configuring scenario in class \(scenarioClass)")
        scenario!.configure()
        logInfo("Clearing persistent data")
        scenario!.clearPersistentData()
        logInfo("Starting bugsnag performance")
        scenario!.startBugsnag()
        logInfo("Starting scenario in class \(scenarioClass)")
        scenario!.run()
        logInfo("========== Completed scenario \(scenarioName) ==========")
        Thread.sleep(forTimeInterval: 2.0)
        scenario!.reportMeasurements()
        Thread.sleep(forTimeInterval: 1.0)
    }

    private func invokeMethod(methodName: String, args: Array<String>) {
        logInfo("Invoking method \(methodName) with args \(args) on \(String(describing: scenario!.self))")

        let sel = NSSelectorFromString(methodName)
        if (!scenario!.responds(to: sel)) {
            fatalError("\(String(describing: scenario!.self)) does not respond to \(methodName). Did you set the @objcMembers annotation on \(String(describing: scenario!.self))?")
        }

        switch args.count {
        case 0:
            scenario!.perform(sel)
        case 1:
            // Note: Parameter must accept a string
            scenario!.perform(sel, with: args[0])
        default:
            fatalError("invoking \(methodName) with args \(args): Fixture currently only supports up to 1 argument")
        }
    }

    static func loadMazeRunnerAddress() -> String {
        logInfo("loadMazeRunnerAddress 1")
        let defaultUrl = Fixture.defaultMazeRunnerURL

        // Only iOS 12 and above will run on BitBar for now
        if #available(iOS 12.0, *) {} else {
            return defaultUrl
        }

        for n in 1...60 {
            logInfo("loadMazeRunnerAddress 2")
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            logInfo("Reading Maze Runner address from fixture_config.json")
            do {
                let fileUrl = URL(fileURLWithPath: "fixture_config",
                                  relativeTo: documentsUrl).appendingPathExtension("json")
                logInfo("loadMazeRunnerAddress 3")
                let savedData = try Data(contentsOf: fileUrl)
                logInfo("loadMazeRunnerAddress 4")
                if let contents = String(data: savedData, encoding: .utf8) {
                    logInfo("loadMazeRunnerAddress 5")
                    logInfo(String(format: "Found fixture_config.json after %d seconds", n))
                    let decoder = JSONDecoder()
                    let jsonData = contents.data(using: .utf8)
                    let config = try decoder.decode(FixtureConfig.self, from: jsonData!)
                    let address = "http://" + config.maze_address
                    logInfo("loadMazeRunnerAddress 6")
                    logInfo("Using Maze Runner address: \(address)")
                    return address
                }
            }
            catch let error as NSError {
                logInfo("loadMazeRunnerAddress 7")
                logWarn("Failed to read fixture_config.json: \(error)")
            }
            logInfo("loadMazeRunnerAddress 8")
            logInfo("Waiting for fixture_config.json to appear")
            sleep(1)
        }

        logInfo("loadMazeRunnerAddress 9")
        logError("Unable to read from fixture_config.json, defaulting to BrowserStack environment")
        return defaultUrl;
    }

    private struct FixtureConfig: Decodable {
        var maze_address: String
    }
}
