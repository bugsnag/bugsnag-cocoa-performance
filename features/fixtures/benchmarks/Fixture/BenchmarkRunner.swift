//
//  BenchmarkRunner.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 09/09/2025.
//

class BenchmarkRunner {
    
    private enum Constants {
        static let numberOfWarmupIterations = 1000
        static let numberOfMeasurementIterations = 100000
        static let numberOfRuns = 5
    }
    
    var fixtureConfig: FixtureConfig?
    var measurements: [BenchmarkMeasurement] = []
    var suite: Suite!
    var totalIterations = 0
    var totalMeasuredTime = 0
    var totalExcludedTime = 0
    var startTime: Date?
    var args: [String]?
    
    func run(suite: Suite, args argsString: String, completion: @escaping () -> ()) {
        self.suite = suite
        totalIterations = 0
        totalExcludedTime = 0
        measurements = []
        startTime = Date()
        args = splitArgs(args: argsString)
        
        logInfo("Starting suite \"\(String(describing: suite))\" with args \"\(args)\"")
        warmUp()
        coolDown()
        
        performMeasuredRuns()
        reportMetrics(completion: completion)
    }
    
    func warmUp() {
        logInfo("Starting warmUp for suite \"\(String(describing: suite))\"")
        suite.startBugsnag(args: args ?? [])
        let warmupConfig = SuiteConfig(numberOfIterations: Constants.numberOfWarmupIterations)
        suite.configure(warmupConfig)
        suite.run()
        logInfo("Finished warmUp for suite \"\(String(describing: suite))\"")
    }
    
    func performMeasuredRuns() {
        logInfo("Starting measured runs for suite \"\(String(describing: suite))\"")
        let measurementConfig = SuiteConfig(
            numberOfIterations: Constants.numberOfMeasurementIterations
        )
        suite.configure(measurementConfig)
        
        for _ in 0..<Constants.numberOfRuns {
            let instrumentation = BenchmarkInstrumentation()
            suite.instrument(instrumentation)
            instrumentation.startExcludedTime()
            suite.run()
            instrumentation.endExcludedTime()
            recordMeasurement(instrumentation.finalMeasurement())
            coolDown()
        }
        logInfo("Finished measured runs for suite \"\(String(describing: suite))\"")
    }
    
    func coolDown() {
        Thread.sleep(forTimeInterval: 0.2)
    }
    
    func recordMeasurement(_ measurement: BenchmarkMeasurement) {
        totalIterations += measurement.iterations
        totalMeasuredTime += measurement.measuredTime
        totalExcludedTime += measurement.excludedTime
        measurements.append(measurement)
    }
    
    func reportMetrics(completion: @escaping () -> Void) {
        logInfo("Reporting metrics for suite \"\(String(describing: suite))\"")
        guard let startTime = startTime else { return }
        var metrics: [String: String] = [:]
        metrics["timestamp"] = "\(nanoseconds(date: startTime))"
        metrics["benchmark"] = String(describing: type(of: suite!))
            .replacingOccurrences(of: "Fixture.", with: "")
        args?.forEach { metrics["\($0)"] = "true" }
        
        metrics["totalTimeTaken"] = "\(totalMeasuredTime + totalExcludedTime)"
        metrics["totalExcludedTime"] = "\(totalExcludedTime)"
        metrics["totalMeasuredTime"] = "\(totalMeasuredTime)"
        metrics["totalIterations"] = "\(totalIterations)"
        
        measurements.enumerated().forEach { index, measurement in
            let runNr = index + 1
            metrics["timeTaken.\(runNr)"] = "\(measurement.timeTaken)"
            metrics["excludedTime.\(runNr)"] = "\(measurement.excludedTime)"
            metrics["measuredTime.\(runNr)"] = "\(measurement.measuredTime)"
            metrics["iterations.\(runNr)"] = "\(measurement.iterations)"
            metrics["cpuUse.\(runNr)"] = "\(measurement.cpuUse)"
        }
        
        logInfo("Measurements recorded \(measurements)")
        
        var request = URLRequest(url: fixtureConfig!.metricsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try? JSONSerialization.data(withJSONObject: metrics)
        guard let jsonData = jsonData else {
            return
        }
        request.httpBody = jsonData

        logInfo("Sending measurements to url \(fixtureConfig!.metricsURL.absoluteString)")
        URLSession.shared.dataTask(with: request, completionHandler: { _, _, error in
            if let error {
                logInfo("Sending measurements failed with error \(error)")
            } else {
                logInfo("Measurements sent successfully")
            }
            completion()
        }).resume()
    }
    
    func splitArgs(args: String) -> [String] {
        return args.split(separator: ",").map(String.init)
    }
    
    func nanoseconds(date: Date) -> Int {
        let calendar = Calendar.current
        let duration = calendar.dateComponents([.nanosecond], from: date)
        return duration.nanosecond ?? 0
    }
}
