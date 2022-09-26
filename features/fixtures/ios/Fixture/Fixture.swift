//
//  Fixture.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import BugsnagPerformance
import Foundation

func fetchAndExecuteCommand() {
    let url = URL(string: "http://bs-local.com:9339/command")!
    
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    NSLog("[Fixture] \(request.httpMethod!) \(request) \(request.allHTTPHeaderFields!)")
    
    URLSession.shared.dataTask(with: request) { data, response, connectionError in
        if let response = response {
            NSLog("[Fixture] \(response)")
        } else if let error = connectionError {
            NSLog("[Fixture] \(error)")
        }
        
        guard let data = data else { return }
        NSLog("[Fixture] \(String(data: data, encoding: .utf8)!)")
        
        let command: Command
        do {
            command = try JSONDecoder().decode(Command.self, from: data)
        } catch {
            NSLog("[Fixture] \(error)")
            return
        }
        
        run(command: command)
    }.resume()
}

func run(command: Command) {
    let scenarioClass: AnyClass = NSClassFromString("Fixture.\(command.scenario)")!
    let scenario = (scenarioClass as! NSObject.Type).init() as! Scenario
    
    let config = BugsnagPerformanceConfiguration.loadConfig()
    config.endpoint = URL(string: "http://bs-local.com:9339/logs")!
    BugsnagPerformance.start(configuration: config)
    
    scenario.run()
}

struct Command: Decodable {
    let scenario: String
}
