//
//  BSGURLsMatchScenario.swift
//  Fixture
//
//  Created by automated-test on 2026-04-08.
//

import Foundation
import BugsnagPerformance

@objcMembers
final class BSGURLsMatchScenario: Scenario {

    // Keep the feature-file case strings in one place.
    private enum CaseName: String {
        case trailingSlash = "trailing_slash"
        case query = "query"
        case schemeCase = "scheme_case"
        case hostCase = "host_case"
        case differentPort = "different_port"
        case differentPath = "different_path"
        case hostMismatch = "host_mismatch"
        case schemeMismatch = "scheme_mismatch"
    }

    // Use a deterministic session for tests (no shared cache/cookies) and explicit timeouts.
    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        cfg.timeoutIntervalForRequest = 10
        cfg.timeoutIntervalForResource = 10
        return URLSession(configuration: cfg)
    }()

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()

        // Enable automatic network instrumentation so network requests create spans.
        bugsnagPerfConfig.autoInstrumentNetworkRequests = true

        // Keep the request URL unchanged so the SDK can apply its own internal-endpoint filtering
        // against the real URL that was requested.
        bugsnagPerfConfig.networkRequestCallback = { info in
            return info
        }
    }

    /// Builds a URL variant for a given case name based on the configured traces URL.
    private func buildURL(for caseName: CaseName) -> URL? {
        let base = fixtureConfig.tracesURL
        guard var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            return nil
        }

        // Ensure path is non-empty (URLComponents can use "" for root).
        if comps.path.isEmpty {
            comps.path = "/"
        }

        switch caseName {
        case .trailingSlash:
            if !comps.path.hasSuffix("/") {
                comps.path += "/"
            }

        case .query:
            comps.query = "x=y"

        case .schemeCase:
            if let scheme = comps.scheme {
                comps.scheme = scheme.uppercased()
            }

        case .hostCase:
            if let host = comps.host {
                comps.host = host.uppercased()
            }

        case .differentPort:
            comps.port = 8443

        case .hostMismatch:
            comps.host = "example2.com"

        case .schemeMismatch:
            let current = comps.scheme?.lowercased()
            comps.scheme = (current == "https") ? "http" : "https"
            // Note: we intentionally do not force a port here; URLComponents will apply defaults
            // implicitly when the port is nil, which helps exercise default-port matching logic.

        case .differentPath:
            // For different_path we intentionally use the reflect endpoint so the request definitely
            // does NOT hit the configured traces endpoint.
            guard var reflectComps = URLComponents(url: fixtureConfig.reflectURL,
                                                   resolvingAgainstBaseURL: false) else {
                return nil
            }
            reflectComps.queryItems = (reflectComps.queryItems ?? []) + [
                URLQueryItem(name: "bsg_case", value: "different_path")
            ]
            return reflectComps.url
        }

        return comps.url
    }

    /// Called via Maze Runner step: invoke "runCase:" with parameter "<case>"
    @objc func runCase(_ caseNameRaw: String) {
        guard let caseName = CaseName(rawValue: caseNameRaw) else {
            logError("BSGURLsMatchScenario: Unknown case '\(caseNameRaw)'")
            fatalError("BSGURLsMatchScenario: Unknown case '\(caseNameRaw)'")
        }

        guard let url = buildURL(for: caseName) else {
            logError("BSGURLsMatchScenario: Failed to build URL for case \(caseNameRaw). tracesURL=\(fixtureConfig.tracesURL)")
            fatalError("BSGURLsMatchScenario: Failed to build URL for case \(caseNameRaw)")
        }

        logDebug("BSGURLsMatchScenario.runCase(\(caseNameRaw)): Requesting URL \(url.absoluteString) (tracesURL=\(fixtureConfig.tracesURL))")

        // Fire a simple GET request; allow instrumentation to create a span if appropriate.
        // We do not block here; Maze steps should handle waiting/assertions (reduces flakiness vs sleep).
        let task = session.dataTask(with: url) { (_, _, err) in
            if let err {
                logDebug("BSGURLsMatchScenario: request error for \(caseNameRaw): \(err)")
            } else {
                logDebug("BSGURLsMatchScenario: request completed for \(caseNameRaw) to \(url.absoluteString)")
            }
        }
        task.resume()
    }

    override func run() {
        // Default run isn't used; tests will invoke runCase: individually.
        logDebug("BSGURLsMatchScenario.run(): no-op")
    }
}
