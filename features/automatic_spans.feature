Feature: Automatic instrumentation spans

  Scenario: AutoInstrumentAppStartsScenario
    Given I run "AutoInstrumentAppStartsScenario" and discard the initial p-value request
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * every span field "name" equals "AppStart/Cold"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals "SPAN_KIND_INTERNAL"
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span string attribute "bugsnag.app_start.type" equals "cold"
    * every span string attribute "bugsnag.span_category" equals "app_start"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" equals "0.0"

  Scenario: AutoInstrumentViewLoadScenario
    Given I run "AutoInstrumentViewLoadScenario" and discard the initial p-value request
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * every span field "name" equals "ViewLoaded/UIKit/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals "SPAN_KIND_INTERNAL"
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span string attribute "bugsnag.span_category" equals "view_load"
    * every span string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" equals "0.0"

  Scenario: Automatically start a network span
    Given I run "AutoInstrumentNetworkScenario" and discard the initial p-value request
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * every span field "name" equals "HTTP/GET"
    * every span string attribute "http.flavor" exists
    * every span string attribute "http.url" matches the regex "http://.*:9340/reflect/"
    * every span string attribute "http.method" equals "GET"
    * every span integer attribute "http.status_code" is greater than 0
    * every span integer attribute "http.response_content_length" is greater than 0
    * every span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals "SPAN_KIND_INTERNAL"
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" equals "0.0"
