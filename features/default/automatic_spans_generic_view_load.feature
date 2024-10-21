Feature: Automatic instrumentation spans AutoInstrumentGenericViewLoadScenario
  Scenario: AutoInstrumentGenericViewLoadScenario
    Given I run "AutoInstrumentGenericViewLoadScenario"
    And I wait for 18 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.AutoInstrumentGenericViewLoadScenario_ViewController<Fixture.AutoInstrumentGenericViewLoadScenario_GenericsClass>"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentGenericViewLoadScenario_ViewController<Fixture.AutoInstrumentGenericViewLoadScenario_GenericsClass>"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentGenericViewLoadScenario_ViewController<Fixture.AutoInstrumentGenericViewLoadScenario_GenericsClass>"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentGenericViewLoadScenario_ViewController<Fixture.AutoInstrumentGenericViewLoadScenario_GenericsClass>"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentGenericViewLoadScenario_ViewController<Fixture.AutoInstrumentGenericViewLoadScenario_GenericsClass>"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentGenericViewLoadScenario_ViewController<Fixture.AutoInstrumentGenericViewLoadScenario_GenericsClass>"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentGenericViewLoadScenario_ViewController<Fixture.AutoInstrumentGenericViewLoadScenario_GenericsClass>"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentGenericViewLoadScenario_ViewController<Fixture.AutoInstrumentGenericViewLoadScenario_GenericsClass>"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentGenericViewLoadScenario_ViewController<Fixture.AutoInstrumentGenericViewLoadScenario_GenericsClass>"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.view.name" equals "Fixture.ViewController"
    * a span string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentGenericViewLoadScenario_ViewController<Fixture.AutoInstrumentGenericViewLoadScenario_GenericsClass>"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
