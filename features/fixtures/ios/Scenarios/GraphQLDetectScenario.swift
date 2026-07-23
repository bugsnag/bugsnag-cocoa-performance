//
//  GraphQLDetectScenario.swift
//  Fixture
//
//  Created by Meiyalagan Ramadurai on 22/07/26.
//

import Foundation
import BugsnagPerformance

@objcMembers
class GraphQLDetectScenario: Scenario {
    
    override func setInitialBugsnagConfiguration() {
            super.setInitialBugsnagConfiguration()
            // Enable network auto-instrumentation so the SDK can detect GraphQL
            bugsnagPerfConfig.autoInstrumentNetworkRequests = true
        }

    override func run() {
        // Force the automatic startup spans to be sent in a separate batch we discard
        waitForCurrentBatch()

        let scenarioNumber = Int(scenarioConfig["scenario_number"] ?? "1") ?? 1

        switch scenarioNumber {
        case 1:
            runDetectionScenario()
        case 2:
            runOperationTypeExtractionScenario()
        case 3:
            runDisplayNameScenario()
        case 4:
            runNonGraphQLScenario()
        case 5:
            runMalformedBodyScenario()
        case 6:
            runEdgeCaseOperationNameScenario()
        case 7:
            runBatchedRequestScenario()
        case 8:
            runGETRequestScenario()
        case 9:
            runMultipleOperationsScenario()
        case 10:
            runSafeAttributesScenario()
        case 11:
            runFirstClassFalseScenario()
        case 12:
            runRequestFailureScenario()
        case 13:
            runIOSClientLibraryScenario()
        case 14:
            runConsistentSpanNamesScenario()
        default:
            break
        }
    }

    // MARK: - Scenario 1: GraphQL Detection via Multiple Methods

    private func runDetectionScenario() {
        let contentType = scenarioConfig["content_type"] ?? "application/json"
        let body = scenarioConfig["body"] ?? "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
        let path = scenarioConfig["url_path"] ?? "/graphql"

        sendPOSTToReflect(path: path, contentType: contentType, body: body)
    }

    // MARK: - Scenario 2: Operation Type Extraction

    private func runOperationTypeExtractionScenario() {
        let body = scenarioConfig["body"] ?? "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"

        sendPOSTToReflect(path: "/graphql", contentType: "application/json", body: body)
    }

    // MARK: - Scenario 3: Display Name Format Validation

    private func runDisplayNameScenario() {
        let body = scenarioConfig["body"] ?? "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
        let path = scenarioConfig["url_path"] ?? "/graphql"

        sendPOSTToReflect(path: path, contentType: "application/json", body: body)
    }

    // MARK: - Scenario 4: Non-GraphQL Requests

    private func runNonGraphQLScenario() {
        let method = scenarioConfig["http_method"] ?? "POST"
        let contentType = scenarioConfig["content_type"] ?? "application/json"
        let body = scenarioConfig["body"] ?? "{\"userId\": \"123\", \"action\": \"get\"}"
        let path = scenarioConfig["url_path"] ?? "/rest/users"

        if method == "GET" {
            sendGETToReflect(path: path)
        } else {
            sendPOSTToReflect(path: path, contentType: contentType, body: body)
        }
    }

    // MARK: - Scenario 5: Malformed/Empty Body

    private func runMalformedBodyScenario() {
        let bodyType = scenarioConfig["body_type"] ?? "empty"
        var body: String

        switch bodyType {
        case "empty":
            body = ""
        case "malformed":
            body = "{invalid json content"
        case "null":
            body = "null"
        case "empty_object":
            body = "{}"
        default:
            body = ""
        }

        sendPOSTToReflect(path: "/graphql", contentType: "application/json", body: body)
    }

    // MARK: - Scenario 6: Edge-Case Operation Names

    private func runEdgeCaseOperationNameScenario() {
        let nameType = scenarioConfig["name_type"] ?? "long"
        var body: String

        switch nameType {
        case "long":
            let longName = String(repeating: "A", count: 128)
            body = "{\"query\": \"query \(longName) { user { id } }\", \"operationName\": \"\(longName)\"}"
        case "underscore_version":
            body = "{\"query\": \"query Get_User_Profile_V2 { user { id } }\", \"operationName\": \"Get_User_Profile_V2\"}"
        case "numeric_suffix":
            body = "{\"query\": \"query GetUser123 { user { id } }\", \"operationName\": \"GetUser123\"}"
        default:
            body = "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
        }

        sendPOSTToReflect(path: "/graphql", contentType: "application/json", body: body)
    }

    // MARK: - Scenario 7: Batched Request

    private func runBatchedRequestScenario() {
        let body = "[{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}, {\"query\": \"query GetPosts { posts { id } }\", \"operationName\": \"GetPosts\"}]"

        sendPOSTToReflect(path: "/graphql", contentType: "application/json", body: body)
    }

    // MARK: - Scenario 8: GET Request with Query Params

    private func runGETRequestScenario() {
        sendGETToReflect(path: "/graphql?query={user{id}}&operationName=GetUser")
    }

    // MARK: - Scenario 9: Multiple Operations

    private func runMultipleOperationsScenario() {
        // Two identical queries
        sendPOSTToReflect(path: "/graphql", contentType: "application/json",
                          body: "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}")

        sendPOSTToReflect(path: "/graphql", contentType: "application/json",
                          body: "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}")

        // One mutation
        sendPOSTToReflect(path: "/graphql", contentType: "application/json",
                          body: "{\"query\": \"mutation CreatePost { createPost { id } }\", \"operationName\": \"CreatePost\"}")

        // One REST GET
        sendGETToReflect(path: "/rest/users/123")
    }

    // MARK: - Scenario 10: Safe Attributes Only

    private func runSafeAttributesScenario() {
        sendPOSTToReflect(path: "/graphql", contentType: "application/json",
                          body: "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}")
    }

    // MARK: - Scenario 11: first_class=false

    private func runFirstClassFalseScenario() {
        sendPOSTToReflect(path: "/graphql", contentType: "application/json",
                          body: "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}")
    }

    // MARK: - Scenario 12: Request Failure

    private func runRequestFailureScenario() {
        let failureType = scenarioConfig["failure_type"] ?? "timeout"

        switch failureType {
        case "timeout":
            // Send to a non-responsive endpoint to trigger timeout
            sendPOSTToReflect(path: "/graphql?delay=60000", contentType: "application/json",
                              body: "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}",
                              timeout: 5.0)
        case "connection_refused":
            // Send to a port nothing is listening on
            let url = URL(string: "http://localhost:1/graphql")!
            sendPOST(url: url, contentType: "application/json",
                     body: "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}")
        case "empty_body":
            sendPOSTToReflect(path: "/graphql?status=204", contentType: "application/json",
                              body: "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}")
        default:
            break
        }
    }

    // MARK: - Scenario 13: iOS Client Library

    private func runIOSClientLibraryScenario() {
        sendPOSTToReflect(path: "/graphql", contentType: "application/json",
                          body: "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}")
    }

    // MARK: - Scenario 14: Consistent Span Names

    private func runConsistentSpanNamesScenario() {
        for _ in 1...3 {
            sendPOSTToReflect(path: "/graphql", contentType: "application/json",
                              body: "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}")
        }
    }

    // MARK: - Helper Methods

    /// Send a POST request to the Maze Runner reflect endpoint
    private func sendPOSTToReflect(path: String, contentType: String, body: String, timeout: TimeInterval = 60.0) {
        let url = URL(string: path, relativeTo: fixtureConfig.reflectURL)!
        sendPOST(url: url, contentType: contentType, body: body, timeout: timeout)
    }

    /// Send a POST request to an arbitrary URL
    private func sendPOST(url: URL, contentType: String, body: String, timeout: TimeInterval = 60.0) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        request.timeoutInterval = timeout

        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                NSLog("GraphQLDetect: POST \(url) -> \(httpResponse.statusCode)")
            } else if let error = error {
                NSLog("GraphQLDetect: POST \(url) -> error: \(error.localizedDescription)")
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
    }

    /// Send a GET request to the Maze Runner reflect endpoint
    private func sendGETToReflect(path: String) {
        let url = URL(string: path, relativeTo: fixtureConfig.reflectURL)!

        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                NSLog("GraphQLDetect: GET \(url) -> \(httpResponse.statusCode)")
            } else if let error = error {
                NSLog("GraphQLDetect: GET \(url) -> error: \(error.localizedDescription)")
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
    }
}
