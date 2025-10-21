Feature: Automatic network instrumentation spans

  Scenario: Automatically start a network span that has a parent
    Given I run "AutoInstrumentNetworkWithParentScenario"
    And I wait for 2 seconds
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "parentSpanId" exists
    * a span field "parentSpanId" is greater than 0
    * a span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
#    * a span string attribute "http.url" matches the regex "http://.*:9[0-9]{3}/reflect\?status=200"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * a span field "kind" equals 1
    * a span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" does not exist
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Automatically start a network span that has no parent
    Given I run "AutoInstrumentNetworkNoParentScenario"
    And I wait for 2 seconds
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
#    * a span string attribute "http.url" matches the regex "http://.*:9[0-9]{3}/reflect\?status=200"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * a span field "kind" equals 1
    * a span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" does not exist
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Auto-capture multiple network spans
    Given I run "AutoInstrumentNetworkMultiple"
    And I wait for 10 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Automatically start a network span that is a file:// scheme
    Given I run "AutoInstrumentFileURLRequestScenario"
    Then I should receive no traces

  Scenario: Don't send an auto network span that failed to send
    Given I run "AutoInstrumentNetworkBadAddressScenario"
    # Only the initial command request should be captured.
    Then I wait for 1 span

  Scenario: Automatically start a network span that has a null URL
    Given I run "AutoInstrumentNetworkNullURLScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
#    * a span string attribute "http.url" matches the regex "http://.*:9[0-9]{3}/reflect\?status=200"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Automatically start a network span triggered by AVAssetDownloadURLSession (must not crash)
    Given I run "AutoInstrumentAVAssetScenario"
    And I wait for 2 seconds
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * a span field "kind" equals 1
    * a span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.instrumentation_message" exists
    * a span string attribute "bugsnag.instrumentation_message" matches the regex "Error.*"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" does not exist
    * a span string attribute "bugsnag.span.category" equals "network"
    * a span string attribute "http.url" equals "unknown"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Capture automatic network span before configuration
    Given I run "AutoInstrumentNetworkPreStartScenario"
    And I wait for 2 seconds
    And I wait for exactly 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
#    * a span string attribute "http.url" matches the regex "http://.*:9[0-9]{3}/reflect\?status=200"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Invalidate calls on shared session should be ignored
    Given I run "AutoInstrumentNetworkSharedSessionInvalidateScenario"
    And I wait for exactly 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
#    * a span string attribute "http.url" matches the regex "http://.*:9[0-9]{3}/reflect\?status=200"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Capture automatic network span before configuration (disabled)
    Given I run "AutoInstrumentNetworkPreStartDisabledScenario"
    And I should receive no traces

  Scenario: AutoInstrumentNetworkCallbackScenario
    Given I run "AutoInstrumentNetworkCallbackScenario"
    And I wait for exactly 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "[HTTP/GET]"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "http.url" equals "https://bugsnag.com"
    * a span string attribute "http.url" equals "https://bugsnag.com/changed"

  Scenario: AutoInstrumentNullNetworkCallbackScenario
    Given I run "AutoInstrumentNullNetworkCallbackScenario"
    # Wait for a long time because there can be a LOT of maze-runner related URL requests before the scenario starts.
    And I wait for 20 seconds
    # There will actually be any number of requests by this point since we're not filtering at all.
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[HTTP/GET]"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "http.url" equals "https://bugsnag.com"

  Scenario: AutoInstrumentNetworkTracePropagationScenario: Allow All
    Given I load scenario "AutoInstrumentNetworkTracePropagationScenario"
    And I configure bugsnag "propagateTraceParentToUrlsMatching" to ".*"
    And I invoke "setCallSitesWithCallSiteStrs:" with parameter "?test=1"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive a reflection
    Then the reflection "traceparent" header matches the regex "^00-[A-Fa-f0-9]{32}-[A-Fa-f0-9]{16}-01"

  Scenario: AutoInstrumentNetworkTracePropagationScenario: Allow None by default
    Given I load scenario "AutoInstrumentNetworkTracePropagationScenario"
    And I invoke "setCallSitesWithCallSiteStrs:" with parameter "?test=1"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive a reflection
    Then the reflection "traceparent" header is not present

  Scenario: AutoInstrumentNetworkTracePropagationScenario: Allow Some
    Given I load scenario "AutoInstrumentNetworkTracePropagationScenario"
    And I configure bugsnag "propagateTraceParentToUrlsMatching" to ".*test.*"
    And I invoke "setCallSitesWithCallSiteStrs:" with parameter "?test=1,?temp=1"
    And I start bugsnag
    And I run the loaded scenario
    Then I wait to receive 2 reflections
    And the reflection "traceparent" header matches the regex "^00-[A-Fa-f0-9]{32}-[A-Fa-f0-9]{16}-01"
    Then I discard the oldest reflection
    And the reflection "traceparent" header is not present
