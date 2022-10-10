Feature: Manual creation of spans

  Scenario: Manually start and end a span
    Given I run "ManualSpanScenario"
    And I wait to receive a trace
    Then the trace "Content-Type" header equals "application/json"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.name" equals "ManualSpanScenario"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.kind" equals "SPAN_KIND_INTERNAL"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.startTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" attribute "telemetry.sdk.version" equals "0.0"

  Scenario: Starting and ending a span before starting the SDK
    Given I run "ManualSpanBeforeStartScenario"
    And I wait to receive a trace
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.name" equals "BeforeStart"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.kind" equals "SPAN_KIND_INTERNAL"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.startTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" attribute "telemetry.sdk.version" equals "0.0"

  Scenario: Starting and ending a span before starting the SDK
    Given I run "ManualViewLoadScenario"
    And I wait to receive 2 traces
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.name" equals "ViewLoaded/UIKit/ManualViewController"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.kind" equals "SPAN_KIND_INTERNAL"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.startTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" attribute "bugsnag.span_category" equals "view_load"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" attribute "bugsnag.view_type" equals "UIKit"
    And I discard the oldest trace
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.name" equals "ViewLoaded/SwiftUI/ManualView"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.kind" equals "SPAN_KIND_INTERNAL"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.startTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0.endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" attribute "bugsnag.span_category" equals "view_load"
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" attribute "bugsnag.view_type" equals "SwiftUI"
