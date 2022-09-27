Feature: Manual creation of spans

  Scenario: Manually start and end a span
    Given I run "ManualSpanScenario"
    And I wait to receive a log
    Then the log "Content-Type" header equals "application/json"
    * the log payload field "resourceSpans.0.scopeSpans.0.spans.0.name" equals "ManualSpanScenario"
    * the log payload field "resourceSpans.0.scopeSpans.0.spans.0.spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * the log payload field "resourceSpans.0.scopeSpans.0.spans.0.traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * the log payload field "resourceSpans.0.scopeSpans.0.spans.0.kind" equals "SPAN_KIND_INTERNAL"
    * the log payload field "resourceSpans.0.scopeSpans.0.spans.0.startTimeUnixNano" matches the regex "^[0-9]+$"
    * the log payload field "resourceSpans.0.scopeSpans.0.spans.0.endTimeUnixNano" matches the regex "^[0-9]+$"
    * the log payload field "resourceSpans.0.resource" attribute "service.name" equals "com.bugsnag.Fixture"
    * the log payload field "resourceSpans.0.resource" attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the log payload field "resourceSpans.0.resource" attribute "telemetry.sdk.version" equals "0.0"
