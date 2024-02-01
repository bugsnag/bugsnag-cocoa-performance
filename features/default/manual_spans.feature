Feature: Manual creation of spans

  # Workaround to clear out the initial startup P request

  Scenario: Retry a manual span
    Given I set the HTTP status code for the next requests to 200,500,200,200
    And I run "RetryScenario"
    And I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "WillRetry"
    Then I discard the oldest trace
    And I invoke "step2"
    And I wait for 2 spans
    * a span field "name" equals "WillRetry"
    * a span field "name" equals "Success"
    * every span bool attribute "bugsnag.span.first_class" is true

  Scenario: Manually start and end a span
    Given I run "ManualSpanScenario"
    And I wait to receive an error
    And the error payload field "events.0.device.id" is stored as the value "bugsnag_device_id"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Integrity" header matches the regex "^sha1 [A-Fa-f0-9]{40}$"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "ManualSpanScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.app.in_foreground" is true
    * every span string attribute "net.host.connection.type" equals "wifi"
    * every span bool attribute "bugsnag.span.first_class" is true
    * the trace payload field "resourceSpans.0.resource" string attribute "bugsnag.app.bundle_version" equals "30"
    * the trace payload field "resourceSpans.0.resource" string attribute "deployment.environment" equals "staging"
    * the trace payload field "resourceSpans.0.resource" string attribute "device.id" equals the stored value "bugsnag_device_id"
    * the trace payload field "resourceSpans.0.resource" string attribute "device.manufacturer" equals "Apple"
    * the trace payload field "resourceSpans.0.resource" string attribute "device.model.identifier" exists
    * the trace payload field "resourceSpans.0.resource" string attribute "host.arch" matches the regex "arm64|amd64"
    * the trace payload field "resourceSpans.0.resource" string attribute "os.name" equals "iOS"
    * the trace payload field "resourceSpans.0.resource" string attribute "os.type" equals "darwin"
    * the trace payload field "resourceSpans.0.resource" string attribute "os.version" exists
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.version" equals "10.0"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

  Scenario: Starting and ending a span before starting the SDK
    Given I run "ManualSpanBeforeStartScenario"
    And I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "BeforeStart"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
    * the trace payload field "resourceSpans.0.resource" string attribute "bugsnag.app.bundle_version" equals "42.42"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.version" equals "42"

  Scenario: Manually report a view load span
    Given I run "ManualViewLoadScenario"
    And I wait for 2 spans
    * the trace "Bugsnag-Span-Sampling" header is present
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[ViewLoad/UIKit]/ManualViewController"
    * a span string attribute "bugsnag.view.name" equals "ManualViewController"
    * a span string attribute "bugsnag.view.type" equals "UIKit"
    * a span field "name" equals "[ViewLoad/SwiftUI]/ManualView"
    * a span string attribute "bugsnag.view.name" equals "ManualView"
    * a span string attribute "bugsnag.view.type" equals "SwiftUI"
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span string attribute "bugsnag.span.category" equals "view_load"

  Scenario: Manually report a SwiftUI view load phase span
    Given I run "ManualViewLoadPhaseScenario"
    And I wait for 2 spans
    * the trace "Bugsnag-Span-Sampling" header is present
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[ViewLoad/SwiftUI]/ManualViewLoadPhaseScenario"
    * a span field "name" equals "[ViewLoadPhase/SomePhase]/ManualViewLoadPhaseScenario"
    * every span string attribute "bugsnag.view.name" equals "ManualViewLoadPhaseScenario"
    * a span string attribute "bugsnag.view.type" equals "SwiftUI"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" is false
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.span.category" equals "view_load_phase"

  Scenario: Manually report a UIViewController load span
    Given I run "ManualUIViewLoadScenario"
    And I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "[ViewLoad/UIKit]/UIViewController"
    * every span string attribute "bugsnag.view.name" equals "UIViewController"
    * every span string attribute "bugsnag.view.type" equals "UIKit"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span string attribute "bugsnag.span.category" equals "view_load"
    * every span bool attribute "bugsnag.span.first_class" is true

  Scenario: Manually start a network span
    Given I run "ManualNetworkSpanScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
    * every span field "name" equals "[HTTP/GET]"
    * every span string attribute "http.flavor" exists
    * every span string attribute "http.url" matches the regex "http://.*:9339/reflect\?status=200"
    * every span string attribute "http.method" equals "GET"
    * every span integer attribute "http.status_code" is greater than 0
    * every span integer attribute "http.response_content_length" is greater than 0
    * every span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" does not exist

  Scenario: Manually start and end a span field "with" batching
    Given I run "BatchingScenario"
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header is present
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
    * a span field "name" equals "Span1"
    * a span field "name" equals "Span2"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true

  Scenario: Manually start and end a span field "with" batching
    Given I run "BatchingScenario"
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header is present
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "Span1"
    * a span field "name" equals "Span2"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
    * every span bool attribute "bugsnag.span.first_class" is true

  Scenario: Manually start and end parent and child spans
    Given I run "ParentSpanScenario"
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
    * a span field "name" equals "SpanParent"
    * a span field "name" equals "SpanChild"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true
    # Note: The child span ends up first in the list of spans.
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.parentSpanId" matches the regex "^[A-Fa-f0-9]{16}$"

  Scenario: Manually start and end first-class = yes span
    Given I run "FirstClassYesScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
    * every span field "name" equals "FirstClassYesScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true

  Scenario: Manually start and end first-class = no span
    Given I run "FirstClassNoScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
    * every span field "name" equals "FirstClassNoScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is false

  Scenario: Trace exceeds the max package size
    Given I set the HTTP status code for the next requests to 402,402,402
    And I run "MaxPayloadSizeScenario"
    And I wait for exactly 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Integrity" header matches the regex "^sha1 [A-Fa-f0-9]{40}$"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the trace "Bugsnag-Uncompressed-Content-Length" header matches the regex "^[0-9]+$"
    * every span field "name" equals "MaxPayloadSizeScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.app.in_foreground" is true
    * every span string attribute "net.host.connection.type" equals "wifi"
    * every span bool attribute "bugsnag.span.first_class" is true
    * the trace payload field "resourceSpans.0.resource" string attribute "bugsnag.app.bundle_version" equals "30"
    * the trace payload field "resourceSpans.0.resource" string attribute "deployment.environment" equals "staging"
    * the trace payload field "resourceSpans.0.resource" string attribute "device.id" exists
    * the trace payload field "resourceSpans.0.resource" string attribute "device.manufacturer" equals "Apple"
    * the trace payload field "resourceSpans.0.resource" string attribute "device.model.identifier" exists
    * the trace payload field "resourceSpans.0.resource" string attribute "host.arch" matches the regex "arm64|amd64"
    * the trace payload field "resourceSpans.0.resource" string attribute "os.name" equals "iOS"
    * the trace payload field "resourceSpans.0.resource" string attribute "os.type" equals "darwin"
    * the trace payload field "resourceSpans.0.resource" string attribute "os.version" exists
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.version" equals "10.0"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
