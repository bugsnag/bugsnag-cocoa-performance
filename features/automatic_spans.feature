Feature: Automatic instrumentation spans

  Scenario: AutoInstrumentAppStartsScenario
    Given I run "AutoInstrumentAppStartsScenario"
    And I wait to receive a trace
    Then the trace "Content-Type" header equals "application/json"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.name" equals "AppStart/Cold"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.kind" equals "SPAN_KIND_INTERNAL"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.startTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "bugsnag.app_start.type" equals "cold"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "bugsnag.span_category" equals "app_start"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" equals "0.0"

  Scenario: AutoInstrumentViewLoadScenario
    Given I run "AutoInstrumentViewLoadScenario"
    And I wait to receive a trace
    Then the trace "Content-Type" header equals "application/json"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.name" equals "ViewLoaded/UIKit/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.kind" equals "SPAN_KIND_INTERNAL"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.startTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "bugsnag.span_category" equals "view_load"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" equals "0.0"

  Scenario: Automatically start a network span
    Given I run "AutoInstrumentNetworkScenario"
    And I wait to receive a trace
    Then the trace "Content-Type" header equals "application/json"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.name" equals "HTTP/GET"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "http.flavor" exists
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "http.url" matches the regex "http://.*:9340/reflect/"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "http.method" equals "GET"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" integer attribute "http.status_code" is greater than 0
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" integer attribute "http.response_content_length" is greater than 0
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "net.host.connection.type" equals "wifi"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.kind" equals "SPAN_KIND_INTERNAL"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.startTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" equals "0.0"
