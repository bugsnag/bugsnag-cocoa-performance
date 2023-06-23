//
//  PerformanceMicrobenchmarkTests.swift
//  BugsnagPerformance-iOSTests
//
//  Created by Robert B on 03/04/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

import XCTest
import BugsnagPerformance

final class PerformanceMicrobenchmarkTests: XCTestCase {
    
    let config = BugsnagPerformanceConfiguration(apiKey: "0123456789abcdef0123456789abcdef")
    let numberOfTestSpans = 10000

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }


    @available(iOS 13.0, *)
    func testCreateAndEndSpansWithSampling() throws {
        config.internal.initialSamplingProbability = 1
        BugsnagPerformance.start(configuration: config)
        self.measure {
            for _ in 0..<numberOfTestSpans {
                let span = BugsnagPerformance.startSpan(name: "Test")
                span.end()
            }
        }
    }
    
    @available(iOS 13.0, *)
    func testCreateAndEndSpansWithoutSampling() throws {
        config.internal.initialSamplingProbability = 0
        BugsnagPerformance.start(configuration: config)
        self.measure {
            for _ in 0..<numberOfTestSpans {
                let span = BugsnagPerformance.startSpan(name: "Test")
                span.end()
            }
        }
    }
    
    @available(iOS 13.0, *)
    func testCreateAndEndViewSpansWithSampling() throws {
        config.internal.initialSamplingProbability = 1
        BugsnagPerformance.start(configuration: config)
        self.measure {
            for _ in 0..<numberOfTestSpans {
                let span = BugsnagPerformance.startViewLoadSpan(name: "Test", viewType: .uiKit)
                span.end()
            }
        }
    }
    
    @available(iOS 13.0, *)
    func testCreateAndEndViewSpansWithoutSampling() throws {
        config.internal.initialSamplingProbability = 0
        BugsnagPerformance.start(configuration: config)
        self.measure {
            for _ in 0..<numberOfTestSpans {
                let span = BugsnagPerformance.startViewLoadSpan(name: "Test", viewType: .uiKit)
                span.end()
            }
        }
    }
    
    @available(iOS 13.0, *)
    func testCreateBatchAndEndSpansWithSampling() throws {
        config.internal.initialSamplingProbability = 1
        BugsnagPerformance.start(configuration: config)
        self.measure {
            var spans: [BugsnagPerformanceSpan] = []
            for _ in 0..<numberOfTestSpans {
                spans.append(BugsnagPerformance.startViewLoadSpan(name: "Test", viewType: .uiKit))
            }
            spans.forEach { $0.end() }
        }
    }
    
    @available(iOS 13.0, *)
    func testCreateBatchAndEndSpansWithoutSampling() throws {
        config.internal.initialSamplingProbability = 0
        BugsnagPerformance.start(configuration: config)
        self.measure {
            var spans: [BugsnagPerformanceSpan] = []
            for _ in 0..<numberOfTestSpans {
                spans.append(BugsnagPerformance.startViewLoadSpan(name: "Test", viewType: .uiKit))
            }
            spans.forEach { $0.end() }
        }
    }
}
