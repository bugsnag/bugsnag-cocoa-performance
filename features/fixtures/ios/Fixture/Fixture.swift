//
//  Fixture.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import Foundation

class Fixture: NSObject {
    var scenario: Scenario? = nil

    func fetchAndExecuteCommand() {
        let url = URL(string: "\(Scenario.mazeRunnerURL)/command")!

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        NSLog("[Fixture] Sending command request to \(Scenario.mazeRunnerURL)/command: \(request.httpMethod!) \(request) \(request.allHTTPHeaderFields!)")

        URLSession.shared.dataTask(with: request) { data, response, connectionError in
            if let response = response {
                if let ur = response as? HTTPURLResponse {
                    NSLog("[Fixture] Server responded: \(ur.statusCode)")
                } else {
                    NSLog("[Fixture] Server responded: \(response)")
                }
            } else if let error = connectionError {
                NSLog("[Fixture] Server responded with error: \(error)")
            }

            guard let data = data else { return }
            NSLog("[Fixture] Server response data: \(String(data: data, encoding: .utf8)!)")

            let command: Command
            do {
                command = try JSONDecoder().decode(Command.self, from: data)
            } catch {
                NSLog("[Fixture] JSON decode error: \(error)")
                return
            }

            NSLog("[Fixture] Response decoded. Dispatching command \(command.action) on main thread")
            DispatchQueue.main.async {
                self.runCommand(command: command)
            }
        }.resume()
    }

    private func runCommand(command: Command) {
        NSLog("[Fixture] Running command [\(command.action)] with args \(command.args)")

        switch command.action {
        case "run_scenario":
            runScenario(scenarioName: command.args[0])
            break
        case "invoke_method":
            invokeMethod(methodName: command.args[0], args: Array(command.args[1...]))
            break;
        default:
            assertionFailure("\(command.action): Unknown command")
        }
    }

    private func runScenario(scenarioName: String) {
        NSLog("[Fixture] Running scenario \(scenarioName)")
        let scenarioClass: AnyClass = NSClassFromString("Fixture.\(scenarioName)")!
        NSLog("[Fixture] Loaded scenario class: \(scenarioClass)")
        scenario = (scenarioClass as! NSObject.Type).init() as! Scenario?
        NSLog("[Fixture] Configuring scenario \(scenarioName)")
        scenario!.configure()
        NSLog("[Fixture] Clearing persistent data")
        scenario!.clearPersistentData()
        NSLog("[Fixture] Starting bugsnag")
        scenario!.startBugsnag()
        NSLog("[Fixture] Running scenario \(scenarioClass)")
        scenario!.run()
        NSLog("[Fixture] Scenario \(scenarioClass) complete")
    }

    private func invokeMethod(methodName: String, args: Array<String>) {
        NSLog("[Fixture] Invoking: \(methodName) with args \(args) on \(String(describing: scenario!.self))")

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

    private struct Command: Decodable {
        let action: String
        let args: Array<String>
    }

}
