//
//  BenchmarkInstrumentation.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 09/09/2025.
//



class BenchmarkInstrumentation {
    
    private enum Phase {
        case idle, excluded, measured
    }
    
    private struct BenchmarkSample {
        let date: Date
        let cpuSample: CPUSample?
    }
    
    private let cpuSampler = CPUSampler()
    
    private var phase: Phase = .idle
    private var iterations = 0
    
    private var excludedTimeStartSamples: [BenchmarkSample] = []
    private var excludedTimeEndSamples: [BenchmarkSample] = []
    
    private var measuredTimeStartSamples: [BenchmarkSample] = []
    private var measuredTimeEndSamples: [BenchmarkSample] = []
    
    func startExcludedTime() {
        guard phase != .excluded else { return }
        endCurrentPhase()
        excludedTimeStartSamples.append(recordSample())
        phase = .excluded
    }
    
    func endExcludedTime() {
        guard phase == .excluded else { return }
        excludedTimeEndSamples.append(recordSample())
        phase = .idle
    }
    
    func startMeasuredTime() {
        guard phase != .measured else { return }
        endCurrentPhase()
        measuredTimeStartSamples.append(recordSample())
        phase = .measured
    }
    
    func endMeasuredTime() {
        guard phase == .measured else { return }
        measuredTimeEndSamples.append(recordSample())
        phase = .idle
    }
    
    func recordIteration() {
        iterations += 1
    }
    
    func finalMeasurement() -> BenchmarkMeasurement {
        var excludedTime = 0
        excludedTimeStartSamples.enumerated().forEach { (index, sample) in
            guard index < excludedTimeEndSamples.count else {
                return
            }
            let startSample = sample
            let endSample = excludedTimeEndSamples[index]
            excludedTime += nanoseconds(from: startSample.date, to: endSample.date)
        }
        
        var measuredTime = 0
        var cpuUse = 0.0
        measuredTimeStartSamples.enumerated().forEach { (index, sample) in
            guard index < measuredTimeEndSamples.count else {
                return
            }
            let startSample = sample
            let endSample = measuredTimeEndSamples[index]
            measuredTime += nanoseconds(from: startSample.date, to: endSample.date)
            if let startCPUSample = startSample.cpuSample, let endCPUSample = endSample.cpuSample {
                cpuUse += endCPUSample.usage(since: startCPUSample)
            }
        }
        
        return BenchmarkMeasurement(
            timeTaken: measuredTime + excludedTime,
            excludedTime: excludedTime,
            measuredTime: measuredTime,
            iterations: iterations,
            cpuUse: cpuUse
        )
    }
    
    private func endCurrentPhase() {
        switch phase {
        case .excluded:
            endExcludedTime()
        case .measured:
            endMeasuredTime()
        default: break
        }
    }
    
    private func recordSample() -> BenchmarkSample {
        BenchmarkSample(date: Date(), cpuSample: cpuSampler.recordSample())
    }
    
    private func nanoseconds(from fromDate: Date, to toDate: Date) -> Int {
        let calendar = Calendar.current
        let duration = calendar.dateComponents([.nanosecond], from: fromDate, to: toDate)
        return duration.nanosecond ?? 0
    }
}
