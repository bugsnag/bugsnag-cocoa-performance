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

func copyDirectory(src: URL, dst: URL) {
    logInfo("Attempting to copy \"\(src)\" to \"\(dst)\"")
    let fm = FileManager.default
    if fm.fileExists(atPath: src.path) {
        do {
            try fm.copyItem(at: src, to: dst)
        } catch {
            logError("Failed to copy \"\(src)\" to \"\(dst)\": \(error)")
        }
    }
}

func copyCachesToDocumentsFolder() {
    let fm = FileManager.default
    let identifier = Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
    let cachesUrl = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    let documentsUrl = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let rootPathComponent = "bugsnag-performance-\(identifier)"
    let sharedPathComponent = "bugsnag-shared-\(identifier)"
    let dstCache = documentsUrl.appendingPathComponent("BugsnagCachesCopy")
    if fm.fileExists(atPath: dstCache.path) {
        do {
            try fm.removeItem(at: dstCache)
        } catch {
            logError("Failed to remove \"\(dstCache)\": \(error)")
        }
    }
    do {
        try fm.createDirectory(atPath: dstCache.path, withIntermediateDirectories: true)
    } catch {
        logError("Failed to create \"\(dstCache)\": \(error)")
    }

    copyDirectory(src: cachesUrl.appendingPathComponent(rootPathComponent), dst: dstCache.appendingPathComponent(rootPathComponent))
    copyDirectory(src: cachesUrl.appendingPathComponent(sharedPathComponent), dst: dstCache.appendingPathComponent(sharedPathComponent))
}

class Fixture: NSObject, CommandReceiver {
    static let defaultMazeRunnerURL = URL(string: "http://bs-local.com:9339")!

    var readyToReceiveCommand = false
    var commandReaderThread: CommandReaderThread?
    var fixtureConfig: FixtureConfig = FixtureConfig(mazeRunnerBaseAddress: defaultMazeRunnerURL)
    let benchmarkRunner = BenchmarkRunner();
    var suite: Suite? = nil
    var args = ""

    override init() {
        super.init()
        copyCachesToDocumentsFolder()
    }

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
            case "run_suite":
                self.loadSuite(suiteName: command.args["suite"] as! String)
                self.args = command.args["args"] as? String ?? ""
                self.runLoadedSuite {
                    self.terminateApp()
                }
                self.readyToReceiveCommand = true
                break
            default:
                assertionFailure("\(command.action): Unknown command")
                self.readyToReceiveCommand = true
            }
        }
    }

    private func loadSuite(suiteName: String) {
        logInfo("========== Loading suite \(suiteName) ==========")
        let suiteClass: AnyClass = NSClassFromString("Fixture.\(suiteName)")!
        logInfo("Loaded suite class: \(suiteClass)")
        suite = (suiteClass as! Suite.Type).init(fixtureConfig: fixtureConfig) as Suite?
    }

    private func runLoadedSuite(completion: @escaping () -> ()) {
        logInfo("Starting suite \(String(describing: suite))")
        benchmarkRunner.run(suite: suite!, args: args, completion: completion)
    }
    
    private func terminateApp() {
        exit(0)
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
