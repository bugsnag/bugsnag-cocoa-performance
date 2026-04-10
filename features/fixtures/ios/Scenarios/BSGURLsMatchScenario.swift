//
//  BSGURLsMatchScenario.swift
//  Fixture
//
//  Created by automated-test on 2026-04-08.
//

import Foundation
import BugsnagPerformance

@objcMembers
class BSGURLsMatchScenario: Scenario {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        // Enable automatic network instrumentation so network requests create spans
        bugsnagPerfConfig.autoInstrumentNetworkRequests = true

        // Don't filter out Maze Runner admin URLs here — we want the instrumentation
        // to see the actual request URL so the SDK's internal endpoint comparison
        bugsnagPerfConfig.networkRequestCallback = { (info: BugsnagPerformanceNetworkRequestInfo) -> BugsnagPerformanceNetworkRequestInfo in
            return info
        }
    }

    // Helper to build URL variants based on the configured traces URL
    private func buildURL(for caseName: String) -> URL? {
        let base = fixtureConfig.tracesURL
        guard var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            return nil
        }

        // Ensure path is non-empty (URLComponents uses "" for root sometimes)
        if comps.path.isEmpty {
            comps.path = "/"
        }

        switch caseName {
        case "trailing_slash":
            if !comps.path.hasSuffix("/") {
                comps.path += "/"
            }
            return comps.url

        case "query":
            comps.query = "x=y"
            return comps.url

        case "scheme_case":
            if let scheme = comps.scheme {
                comps.scheme = scheme.uppercased()
            }
            return comps.url

        case "host_case":
            if let host = comps.host {
                comps.host = host.uppercased()
            }
            return comps.url

        case "explicit_port":
            // Only meaningful when the configured endpoint is on the scheme default port.
            // Maze defaults to 9339, so skip this case in that environment.
            let scheme = (comps.scheme ?? "").lowercased()
            let defaultPort = (scheme == "https") ? 443 : (scheme == "http" ? 80 : nil)

            // If endpoint already uses a non-default port, this case can't test implicit vs explicit.
            if let p = comps.port, defaultPort != nil, p != defaultPort {
                return nil // caller should ignore this example
            }

            if comps.port == nil, let dp = defaultPort {
                comps.port = dp
            }
            return comps.url

        case "different_port":
            comps.port = 8443
            return comps.url

        case "different_path":
            guard var reflectComps = URLComponents(url: fixtureConfig.reflectURL,
                                                   resolvingAgainstBaseURL: false) else {
                return nil
            }
            reflectComps.queryItems = (reflectComps.queryItems ?? []) + [
                URLQueryItem(name: "bsg_case", value: "different_path")
            ]
            return reflectComps.url

        case "host_mismatch":
            comps.host = "example2.com"
            return comps.url

        case "scheme_mismatch":
            let current = comps.scheme?.lowercased()
            let newScheme = (current == "https") ? "http" : "https"
            comps.scheme = newScheme
            // If an explicit port was present, keep it; otherwise clear port so defaults apply for new scheme
            if comps.port == nil {
                // Leave nil so URLComponents uses no explicit port (default inferred by consumers)
            }
            return comps.url

        default:
            return nil
        }
    }

    // Called via Maze Runner step: invoke "runCase:" with parameter "<case>"
    @objc func runCase(_ caseName: String) {
        guard let url = buildURL(for: caseName) else {
            logError("BSGURLsMatchScenario: Failed to build URL for case \(caseName)")
            return
        }

        logDebug("BSGURLsMatchScenario.runCase(\(caseName)): Requesting URL \(url.absoluteString)")

        // Fire a simple GET request; allow instrumentation to create a span if appropriate.
        let task = URLSession.shared.dataTask(with: url) { (data, resp, err) in
            if let e = err {
                logDebug("BSGURLsMatchScenario: request error: \(e)")
            } else {
                logDebug("BSGURLsMatchScenario: request completed to \(url)")
            }
        }
        task.resume()

        // Allow time for instrumentation lifecycle + trace export to happen. This is conservative.
        Thread.sleep(forTimeInterval: 1.0)
    }

    override func run() {
        // Default run isn't used; tests will invoke runCase: individually.
        logDebug("BSGURLsMatchScenario.run(): no-op")
    }
}
