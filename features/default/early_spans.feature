Feature: Early spans

  Scenario: Make sure OnSpanEnd callbacks also get called for early spans.
    Given I run "EarlySpanOnEndScenario"
    And I wait to receive 1 span
    Then the trace "Content-Type" header equals "application/json"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "kind" equals 3
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: ModifyEarlySpansScenario
    Given I run "ModifyEarlySpansScenario"
    And I wait to receive 5 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:5"
    * a span field "name" equals "[AppStart/iOSCold]"
    * a span field "name" equals "[AppStartPhase/App launching - pre main()]"
    * a span field "name" equals "[AppStartPhase/App launching - post main()]"
    * a span field "name" equals "[AppStartPhase/UI init]"
    * a span field "name" equals "[HTTP/GET]"
    * a span field "kind" equals 1
    * a span field "kind" equals 3
    * a span string attribute "bugsnag.app_start.type" equals "cold"
    * a span string attribute "bugsnag.phase" equals "App launching - pre main()"
    * a span string attribute "bugsnag.phase" equals "App launching - post main()"
    * a span string attribute "bugsnag.phase" equals "UI init"
    * a span string attribute "bugsnag.span.category" equals "app_start"
    * a span string attribute "bugsnag.span.category" equals "app_start_phase"
    * every span string attribute "modifiedOnEnd" equals "yes"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
