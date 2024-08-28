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
    static let defaultMazeRunnerURL = URL(string: "http://bs-local.com:9339")!

    var readyToReceiveCommand = false
    var commandReaderThread: CommandReaderThread?
    var fixtureConfig: FixtureConfig = FixtureConfig(mazeRunnerBaseAddress: defaultMazeRunnerURL)
    var scenario: Scenario? = nil

    func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.loadMazeRunnerAddress { address in
                self.fixtureConfig = FixtureConfig(mazeRunnerBaseAddress: address)
                self.beginReceivingCommands(fixtureConfig: self.fixtureConfig)
            }
        }
    }

    func beginReceivingCommands(fixtureConfig: FixtureConfig) {
        readyToReceiveCommand = true
        commandReaderThread = CommandReaderThread(fixtureConfig: fixtureConfig, commandReceiver: self)
        commandReaderThread!.start()
    }

    func canReceiveCommand() -> Bool {
        return readyToReceiveCommand
    }

    func receiveCommand(command: MazeRunnerCommand) {
        readyToReceiveCommand = false
        DispatchQueue.main.async {
            logInfo("Executing command [\(command.action)] with args \(command.args)")
            switch command.action {
            case "load_scenario":
                self.loadScenario(scenarioName: command.args["scenario"] as! String)
                self.readyToReceiveCommand = true
                break
            case "configure_bugsnag":
                self.configureBugsnag(path: command.args["path"] as! String,
                                      value: command.args["value"] as! String)
                self.readyToReceiveCommand = true
                break
            case "start_bugsnag":
                self.startBugsnag()
                self.readyToReceiveCommand = true
                break
            case "run_loaded_scenario":
                self.runLoadedScenario(completion: {
                    self.readyToReceiveCommand = true
                })
                break
            case "run_scenario":
                self.runScenario(scenarioName: command.args["scenario"] as! String, completion: {
                    self.readyToReceiveCommand = true
                })
                break
            case "invoke_method":
                self.invokeMethod(methodName: command.args["method"] as! String,
                                        args: command.args["arguments"] as! [String])
                self.readyToReceiveCommand = true
                break
            case "background":
                self.scenario?.enterBackground(forSeconds: Int(command.args["duration"] as! String)!)
                self.readyToReceiveCommand = true
                break
            case "noop":
                self.readyToReceiveCommand = true
                break
            default:
                assertionFailure("\(command.action): Unknown command")
                self.readyToReceiveCommand = true
            }
        }
    }

    private func loadScenario(scenarioName: String) {
        logInfo("========== Loading scenario \(scenarioName) ==========")
        let scenarioClass: AnyClass = NSClassFromString("Fixture.\(scenarioName)")!
        logInfo("Loaded scenario class: \(scenarioClass)")
        scenario = (scenarioClass as! Scenario.Type).init(fixtureConfig: fixtureConfig) as Scenario?
        logInfo("Configuring scenario in class \(scenarioClass)")
        scenario!.configure()
        logInfo("Clearing persistent data")
        scenario!.clearPersistentData()
    }

    private func configureBugsnag(path: String, value: String) {
        logInfo("Configuring bugsnag [\(path)] to [\(value)]")
        scenario!.configureBugsnag(path: path, value: value)
    }

    private func startBugsnag() {
        logInfo("Starting bugsnag performance")
        scenario!.startBugsnag()
    }

    private func runLoadedScenario(completion: @escaping () -> ()) {
        logInfo("Starting scenario \(String(describing: scenario))")
        scenario!.run()
        logInfo("========== Completed scenario \(String(describing: scenario)) ==========")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.scenario!.reportMeasurements()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion()
            }
        }
    }

    private func runScenario(scenarioName: String, completion: @escaping () -> ()) {
        loadScenario(scenarioName: scenarioName)
        startBugsnag()
        runLoadedScenario(completion: completion)
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

    func loadMazeRunnerAddress(completion: (URL)->()) {
        let defaultUrl = Fixture.defaultMazeRunnerURL

        // Only iOS 12 and above will run on BitBar for now
        if #available(iOS 12.0, *) {} else {
            completion(defaultUrl)
            return
        }

        for n in 1...60 {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            logInfo("Reading Maze Runner address from fixture_config.json")
            do {
                let fileUrl = URL(fileURLWithPath: "fixture_config",
                                  relativeTo: documentsUrl).appendingPathExtension("json")
                let savedData = try Data(contentsOf: fileUrl)
                if let contents = String(data: savedData, encoding: .utf8) {
                    logInfo(String(format: "Found fixture_config.json after %d seconds", n))
                    let decoder = JSONDecoder()
                    let jsonData = contents.data(using: .utf8)
                    let config = try decoder.decode(FixtureConfigJSON.self, from: jsonData!)
                    let address = "http://" + config.maze_address
                    logInfo("Using Maze Runner address: \(address)")
                    completion(URL(string: address)!)
                    return
                }
            }
            catch let error as NSError {
                logWarn("Failed to read fixture_config.json: \(error)")
            }
            logInfo("Waiting for fixture_config.json to appear")
            sleep(1)
        }

        logError("Unable to read from fixture_config.json, defaulting to BrowserStack environment")
        completion(defaultUrl)
        return
    }

    private struct FixtureConfigJSON: Decodable {
        var maze_address: String
    }
}

class PresetFixture: Fixture {
    let scenarioName: String
    init(scenarioName: String) {
        self.scenarioName = scenarioName
    }

    override func start() {
        receiveCommand(command: MazeRunnerCommand(uuid: "0", action: "load_scenario", args: ["scenario": scenarioName], message: ""))
        receiveCommand(command: MazeRunnerCommand(uuid: "0", action: "start_bugsnag", args: [:], message: ""))
        receiveCommand(command: MazeRunnerCommand(uuid: "0", action: "run_loaded_scenario", args: [:], message: ""))
    }
}
