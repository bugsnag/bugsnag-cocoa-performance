Feature: Automatic swift UI spans

  Scenario: AutoInstrumentSwiftUIScenario no change
    Given I run "AutoInstrumentSwiftUIScenario"
    And I wait to receive at least 3 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[ViewLoad/SwiftUI]/My VStack view"
    * a span field "name" equals "[ViewLoadPhase/body]/My VStack view"
    * a span field "name" equals "[ViewLoadPhase/body]/My Image view"
    # ios < 15 won't have the "view appearing" span
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.span.category" equals "view_load_phase"
    * a span string attribute "bugsnag.view.name" equals "My VStack view"
    * a span string attribute "bugsnag.view.name" equals "My Image view"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span string attribute "bugsnag.view.type" equals "SwiftUI"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: AutoInstrumentSwiftUIScenario with change
    Given I run "AutoInstrumentSwiftUIScenario"
    And I wait to receive at least 3 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[ViewLoad/SwiftUI]/My VStack view"
    * a span field "name" equals "[ViewLoadPhase/body]/My VStack view"
    * a span field "name" equals "[ViewLoadPhase/body]/My Image view"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.span.category" equals "view_load_phase"
    * a span string attribute "bugsnag.view.name" equals "My VStack view"
    * a span string attribute "bugsnag.view.name" equals "My Image view"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span string attribute "bugsnag.view.type" equals "SwiftUI"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    And I discard every trace
    And I invoke "switchView"
    Then I wait to receive at least 2 spans
    * a span field "name" equals "[ViewLoad/SwiftUI]/Text"
    * a span field "name" equals "[ViewLoadPhase/body]/Text"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.span.category" equals "view_load_phase"
    * every span string attribute "bugsnag.view.name" equals "Text"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span string attribute "bugsnag.view.type" equals "SwiftUI"

  Scenario: AutoInstrumentSwiftUIDeferredScenario toggleEndSpanDefer
    Given I run "AutoInstrumentSwiftUIDeferredScenario"
    And I wait to receive at least 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[ViewLoadPhase/body]/vstack1"
    * a span field "name" equals "[ViewLoadPhase/body]/text1"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span string attribute "bugsnag.span.category" equals "view_load_phase"
    * a span string attribute "bugsnag.view.name" equals "vstack1"
    * a span string attribute "bugsnag.view.name" equals "text1"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    Then I discard every trace
    And I invoke "toggleEndSpanDefer"
    And I wait to receive at least 2 spans
    * a span field "name" equals "[ViewLoadPhase/body]/vstack1"
    * a span field "name" equals "[ViewLoadPhase/body]/text1"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span string attribute "bugsnag.span.category" equals "view_load_phase"
    * a span string attribute "bugsnag.view.name" equals "vstack1"
    * a span string attribute "bugsnag.view.name" equals "text1"

  Scenario: AutoInstrumentSwiftUIDeferredScenario toggle everything
    Given I run "AutoInstrumentSwiftUIDeferredScenario"
    And I wait to receive at least 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[ViewLoadPhase/body]/vstack1"
    * a span field "name" equals "[ViewLoadPhase/body]/text1"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span string attribute "bugsnag.span.category" equals "view_load_phase"
    * a span string attribute "bugsnag.view.name" equals "vstack1"
    * a span string attribute "bugsnag.view.name" equals "text1"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    Then I discard every trace
    And I invoke "toggleEndSpanDefer"
    And I wait to receive at least 2 spans
    * a span field "name" equals "[ViewLoadPhase/body]/vstack1"
    * a span field "name" equals "[ViewLoadPhase/body]/text1"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span string attribute "bugsnag.span.category" equals "view_load_phase"
    * a span string attribute "bugsnag.view.name" equals "vstack1"
    * a span string attribute "bugsnag.view.name" equals "text1"
    Then I discard every trace
    And I invoke "toggleHideText1"
    And I wait to receive at least 2 spans
    * a span field "name" equals "[ViewLoad/SwiftUI]/vstack1"
    * a span field "name" equals "[ViewLoadPhase/body]/vstack1"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.span.category" equals "view_load_phase"
    * every span string attribute "bugsnag.view.name" equals "vstack1"
