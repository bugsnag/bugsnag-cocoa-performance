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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.cocoaperformance"
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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.cocoaperformance"
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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.cocoaperformance"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
    * every span field "name" equals "[HTTP/GET]"
    * every span string attribute "http.flavor" exists
    * every span string attribute "http.url" matches the regex "http://.*:9[0-9]{3}/reflect\?status=200"
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

  Scenario: Manually start a network span with callback set to nil
    Given I run "ManualNetworkSpanCallbackSetToNilScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header is present
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.cocoaperformance"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * a span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * a span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * a span field "kind" equals 1
    * a span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * a span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" does not exist

  Scenario: Manually start and end a span field "with" batching
    Given I run "BatchingScenario"
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header is present
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.cocoaperformance"
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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.cocoaperformance"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
    * every span bool attribute "bugsnag.span.first_class" is true

  Scenario: Manually start and end parent and child spans
    Given I run "ParentSpanScenario"
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.cocoaperformance"
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

  Scenario: Manually start and end child span with a manually defined parent
    Given I run "ManualParentSpanScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.cocoaperformance"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
    * a span field "name" equals "SpanChild"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" equals "123456789abcdef0fedcba9876543210"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true
    # Note: The child span ends up first in the list of spans.
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.parentSpanId" equals "23456789abcdef01"

  Scenario: Manually start and end first-class = yes span
    Given I run "FirstClassYesScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.cocoaperformance"
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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.cocoaperformance"
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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.cocoaperformance"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.version" equals "10.0"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

  Scenario: Set attributes in a span
    Given I run "SetAttributesScenario"
    And I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * a span string attribute "a" equals "xyz"
    * every span bool attribute "b" does not exist
    * every span bool attribute "d" does not exist
    * a span array attribute "e" is empty
    * a span array attribute "f" is empty
    * a span array attribute "x" is empty
    * a span array attribute "c" contains the string value "array_0" at index 0
    * a span array attribute "c" contains the integer value 1 at index 1
    * a span array attribute "c" contains the value true at index 2
    * a span array attribute "c" contains the float value 1.5 at index 3

  Scenario: Set attributes in a span with limits set
    Given I run "SetAttributesWithLimitsScenario"
    And I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * a span string attribute "a" equals "1234567890*** 1 CHARS TRUNCATED"
    * a span array attribute "b" contains the integer value 1 at index 0
    * a span array attribute "b" contains the integer value 2 at index 1
    * a span array attribute "b" contains the integer value 3 at index 2
    * a span array attribute "b" contains no value at index 3

  Scenario: Set attributes in a span with an attribute count limit set
    Given I run "SetAttributeCountLimitScenario"
    And I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span string attribute "a" does not exist

  Scenario: Set OnEnd
    Given I run "OnEndCallbackScenario"
    And I wait for exactly 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"

  Scenario: Frame metrics - no slow frames
    Given I run "FrameMetricsNoSlowFramesScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "FrameMetricsNoSlowFramesScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span integer attribute "bugsnag.rendering.total_frames" is greater than 0
    * a span integer attribute "bugsnag.rendering.slow_frames" equals 0
    * a span integer attribute "bugsnag.rendering.frozen_frames" equals 0

  Scenario: Frame metrics - slow frames
    Given I run "FrameMetricsSlowFramesScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "FrameMetricsSlowFramesScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span integer attribute "bugsnag.rendering.total_frames" is greater than 0
    * a span integer attribute "bugsnag.rendering.slow_frames" equals 3
    * a span integer attribute "bugsnag.rendering.frozen_frames" equals 0

  Scenario: Frame metrics - frozen frames
    Given I run "FrameMetricsFronzenFramesScenario"
    And I wait for 3 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:3"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "FrameMetricsFronzenFramesScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span integer attribute "bugsnag.rendering.total_frames" is greater than 4
    * a span integer attribute "bugsnag.rendering.slow_frames" equals 2
    * a span integer attribute "bugsnag.rendering.frozen_frames" equals 2
    * the span named "FrameMetricsFronzenFramesScenario" is the parent of every span named "FrozenFrame"

  Scenario: Frame metrics - autoInstrumentRendering off
    Given I run "FrameMetricsAutoInstrumentRenderingOffScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "FrameMetricsAutoInstrumentRenderingOffScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span integer attribute "bugsnag.rendering.total_frames" does not exist
    * every span integer attribute "bugsnag.rendering.slow_frames" does not exist
    * every span integer attribute "bugsnag.rendering.frozen_frames" does not exist

  Scenario: Frame metrics - span instrumentRendering off
    Given I run "FrameMetricsSpanInstrumentRenderingOffScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "FrameMetricsSpanInstrumentRenderingOffScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span integer attribute "bugsnag.rendering.total_frames" does not exist
    * every span integer attribute "bugsnag.rendering.slow_frames" does not exist
    * every span integer attribute "bugsnag.rendering.frozen_frames" does not exist

  Scenario: Frame metrics - non firstClass span with instrumentRendering off
    Given I run "FrameMetricsNonFirstClassSpanInstrumentRenderingOnScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "FrameMetricsNonFirstClassSpanInstrumentRenderingOnScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is false
    * a span integer attribute "bugsnag.rendering.total_frames" is greater than 0
    * a span integer attribute "bugsnag.rendering.slow_frames" equals 3
    * a span integer attribute "bugsnag.rendering.frozen_frames" equals 0
