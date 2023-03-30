//
//  Fixture.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import Foundation

func fetchAndExecuteCommand() {
    NSLog("[Fixture] Preparing to load scenario from \(Scenario.mazeRunnerURL)/command")
    let url = URL(string: "\(Scenario.mazeRunnerURL)/command")!
    
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    NSLog("[Fixture] Sending command request \(request.httpMethod!) \(request) \(request.allHTTPHeaderFields!)")
    
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
        
        NSLog("[Fixture] Response decoded. Dispatching command \(command.scenario) on main thread")
        DispatchQueue.main.async {
            run(command: command)
        }
    }.resume()
}

func run(command: Command) {
    NSLog("[Fixture] Running command: \(command.scenario)")
    let scenarioClass: AnyClass = NSClassFromString("Fixture.\(command.scenario)")!
    NSLog("[Fixture] Loaded scenario class: \(scenarioClass)")
    let scenario = (scenarioClass as! NSObject.Type).init() as! Scenario
    NSLog("[Fixture] Configuring scenario \(scenario)")
    scenario.configure()
    NSLog("[Fixture] Clearing persistent data")
    scenario.clearPersistentData()
    NSLog("[Fixture] Starting bugsnag")
    scenario.startBugsnag()
    NSLog("[Fixture] Running scenario")
    scenario.run()
    NSLog("[Fixture] Scenario complete")
}

struct Command: Decodable {
    let scenario: String
}
