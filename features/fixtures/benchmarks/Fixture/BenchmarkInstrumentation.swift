//
//  BenchmarkInstrumentation.swift
//  Fixture
//
//  Created by Robert Bartoszewski on 09/09/2025.
//

import Foundation



class BenchmarkInstrumentation {
    
    private enum Phase {
        case idle, excluded, measured
    }
    
    private struct BenchmarkSample {
        let date: Date
        let cpuSample: CPUSample?
    }
    
    private let cpuSampler = CPUSampler()
    
    private var phase: Phase = .idle {
        didSet {
            currentPhaseStart = clock_gettime_nsec_np(CLOCK_MONOTONIC)
        }
    }
    private var currentPhaseStart: UInt64 = 0
    private var currentCpuSample: CPUSample?
    
    private var excludedTime: UInt64 = 0
    private var measuredTime: UInt64 = 0
    private var iterations = 0
    private var cpuUse = 0.0

    
    func startExcludedTime() {
        guard phase != .excluded else { return }
        endCurrentPhase()
        phase = .excluded
    }
    
    func endExcludedTime() {
        guard phase == .excluded else { return }
        excludedTime += clock_gettime_nsec_np(CLOCK_MONOTONIC) - currentPhaseStart
        phase = .idle
    }
    
    func startMeasuredTime() {
        guard phase != .measured else { return }
        endCurrentPhase()
        currentCpuSample = cpuSampler.recordSample()
        phase = .measured
    }
    
    func endMeasuredTime() {
        guard phase == .measured else { return }
        measuredTime += clock_gettime_nsec_np(CLOCK_MONOTONIC) - currentPhaseStart
        if let cpuSample = currentCpuSample {
            cpuUse += cpuSampler.recordSample()?.usage(since: cpuSample) ?? 0
        }
        phase = .idle
    }
    
    func recordIteration() {
        iterations += 1
    }
    
    func finalMeasurement() -> BenchmarkMeasurement {
        BenchmarkMeasurement(
            timeTaken: Int(measuredTime + excludedTime),
            excludedTime: Int(excludedTime),
            measuredTime: Int(measuredTime),
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
    
    private func nanoseconds(from fromDate: Date, to toDate: Date) -> Int {
        let calendar = Calendar.current
        let duration = calendar.dateComponents([.nanosecond], from: fromDate, to: toDate)
        return duration.nanosecond ?? 0
    }
}
