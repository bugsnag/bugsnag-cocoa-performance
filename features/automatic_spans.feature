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
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" attribute "bugsnag.app_start.type" equals "cold"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" attribute "bugsnag.span_category" equals "app_start"
    * the trace payload field "resourceSpans.0.resource" attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" attribute "telemetry.sdk.version" equals "0.0"

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
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" attribute "bugsnag.span_category" equals "view_load"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" attribute "bugsnag.view_type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" attribute "telemetry.sdk.version" equals "0.0"
