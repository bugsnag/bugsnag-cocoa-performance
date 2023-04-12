Feature: Automatic instrumentation spans

  Scenario: AutoInstrumentAppStartsScenario
    Given I run "AutoInstrumentAppStartsScenario" and discard the initial p-value request
    And I wait for 4 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:4"
    * a span field "name" equals "AppStart/Cold"
    * a span field "name" equals "AppStartPhase/App launching - pre main()"
    * a span field "name" equals "AppStartPhase/App launching - post main()"
    * a span field "name" equals "AppStartPhase/UI init"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.app_start.type" equals "cold"
    * every span string attribute "bugsnag.span.category" equals "app_start"
    * every span bool attribute "bugsnag.span.first_class" does not exist
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

  Scenario: AutoInstrumentViewLoadScenario
    Given I run "AutoInstrumentViewLoadScenario" and discard the initial p-value request
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * every span field "name" equals "ViewLoad/UIKit/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span string attribute "bugsnag.span.category" equals "view_load"
    * every span string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * every span bool attribute "bugsnag.span.first_class" is true
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

  Scenario: AutoInstrumentSubViewLoadScenario
    Given I run "AutoInstrumentSubViewLoadScenario" and discard the initial p-value request
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * a span field "name" equals "ViewLoad/UIKit/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span field "name" equals "ViewLoad/UIKit/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" is false
    * the trace payload field "resourceSpans.0.scopeSpans.0.spans.0" string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

  Scenario: Automatically start a network span
    Given I run "AutoInstrumentNetworkScenario" and discard the initial p-value request
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * every span field "name" equals "HTTP/GET"
    * every span string attribute "http.flavor" exists
    * every span string attribute "http.url" matches the regex "http://.*:9340/reflect/"
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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.Fixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"
