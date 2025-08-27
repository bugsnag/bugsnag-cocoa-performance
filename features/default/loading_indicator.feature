Feature: LoadingIndicator view to mark data loading phase

  Scenario: SimpleStopLoadingIndicatorViewScenario
    Given I run "SimpleStopLoadingIndicatorViewScenario"
    And I wait for 8 spans
    And I wait for 2 seconds
    * no span field "name" equals "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    And I invoke "step2"
    And I wait for 10 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDataLoading]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span named "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" is a child of span named "[AppStartPhase/UI init]"
    * a span named "[ViewLoadPhase/loadView]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidAppear]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDataLoading]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span named "[ViewLoad/UIKit]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" ended at the same time as a span named "[ViewLoadPhase/viewDataLoading]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDataLoading]/Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController" duration is equal or greater than 2.0
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.view.name" equals "Fixture.SimpleStopLoadingIndicatorViewScenario_ViewController"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"