Feature: LoadingIndicator view to mark data loading phase

  Scenario: LoadingIndicatorViewSimpleStopScenario
    Given I run "LoadingIndicatorViewSimpleStopScenario"
    And I wait for 17 spans
    And I wait for 2 seconds
    * no span field "name" equals "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    And I invoke "finishLoading"
    And I wait for 19 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDataLoading]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span named "[ViewLoadPhase/loadView]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidAppear]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDataLoading]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController" ended at the same time as a span named "[ViewLoadPhase/viewDataLoading]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDataLoading]/Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController" duration is equal or greater than 2.0
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.view.name" equals "Fixture.LoadingIndicatorViewSimpleStopScenario_ViewController"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: LoadingIndicatorViewSimpleRemoveScenario
    Given I run "LoadingIndicatorViewSimpleRemoveScenario"
    And I wait for 17 spans
    And I wait for 2 seconds
    * no span field "name" equals "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    And I invoke "finishLoading"
    And I wait for 19 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDataLoading]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span named "[ViewLoadPhase/loadView]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidAppear]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDataLoading]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span named "[ViewLoad/UIKit]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController" ended at the same time as a span named "[ViewLoadPhase/viewDataLoading]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDataLoading]/Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController" duration is equal or greater than 2.0
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.view.name" equals "Fixture.LoadingIndicatorViewSimpleRemoveScenario_ViewController"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

