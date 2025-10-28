//
//  StartupConfiguration.swift
//  Fixture
//
//  Created by Daria Bialobrzeska on 15/09/2025.
//

import Foundation

class StartupConfiguration: Decodable, Encodable {
    var configurationFile: String = "startupConfig.json"
    public var apiKey: String
    public var endpoint: URL
    public var autoInstrumentAppStarts: Bool
    public var autoInstrumentViewControllers: Bool
    public var scenarioName: String

    init(configFile: String?) {
        configurationFile = (configFile != nil) ? configFile! : configurationFile
        apiKey = "12312312312312312312312312312312"
        endpoint = URL(string: "http://bs-local.com:9339/traces")!
        autoInstrumentAppStarts = false
        autoInstrumentViewControllers = false
        scenarioName = ""
    }

    func saveStartupConfig() {
        let encoder = JSONEncoder()

        if let encodedData = try? encoder.encode(self) {
            do {
                let fileManager = FileManager.default
                let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let fileURL = documentDirectory.appendingPathComponent(self.configurationFile)
                try encodedData.write(to: fileURL)
            }
            catch {
                logError("Failed to write startup configuration: \(error)")
            }
        }

    }

    func loadStartupConfig() -> Bool {
        var fileURL: URL
        do {
            let fileManager = FileManager.default
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            fileURL = documentDirectory.appendingPathComponent(self.configurationFile)

            let data = try Data(contentsOf: fileURL)

            let decoder = JSONDecoder()
            let loadedData = try decoder.decode(StartupConfiguration.self, from: data)

            // update self fields
            self.scenarioName = loadedData.scenarioName
            self.apiKey = loadedData.apiKey
            self.endpoint = loadedData.endpoint
            self.autoInstrumentAppStarts = loadedData.autoInstrumentAppStarts
            self.autoInstrumentViewControllers = loadedData.autoInstrumentViewControllers

            try fileManager.removeItem(at: fileURL)
        } catch {
            logError("Error processing configuration file: \(error)")
            return false
        }
        return true
    }
}
