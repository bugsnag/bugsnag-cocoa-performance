Feature: Automatic instrumentation spans

  Scenario: AutoInstrumentAppStartsScenario
    Given I run "AutoInstrumentAppStartsScenario"
    And I wait for 4 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:4"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[AppStart/iOSCold]"
    * a span field "name" equals "[AppStartPhase/App launching - pre main()]"
    * a span field "name" equals "[AppStartPhase/App launching - post main()]"
    * a span field "name" equals "[AppStartPhase/UI init]"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.app_start.type" equals "cold"
    * a span string attribute "bugsnag.phase" equals "App launching - pre main()"
    * a span string attribute "bugsnag.phase" equals "App launching - post main()"
    * a span string attribute "bugsnag.phase" equals "UI init"
    * a span string attribute "bugsnag.span.category" equals "app_start"
    * a span string attribute "bugsnag.span.category" equals "app_start_phase"
    * every span bool attribute "bugsnag.span.first_class" does not exist
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: AutoInstrumentViewLoadScenario
    Given I run "AutoInstrumentViewLoadScenario"
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
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.view.name" equals "Fixture.ViewController"
    * a span string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentViewLoadScenario_ViewController"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: AutoInstrumentSubViewLoadScenario
    Given I run "AutoInstrumentSubViewLoadScenario"
    And I wait for 2 seconds
    And I wait for 27 spans
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
    * a span named "[ViewLoadPhase/loadView]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/viewDidAppear]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.view.name" equals "Fixture.ViewController"
    * a span string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" is false
    * a span string attribute "bugsnag.view.type" equals "UIKit"
    * a span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentSubViewLoadScenario_ViewController"
    * a span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentSubViewLoadScenario_SubViewController"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: AutoInstrumentTabViewLoadScenario
    Given I run "AutoInstrumentTabViewLoadScenario"
    And I wait for 2 seconds
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
    * no span field "name" equals "[ViewLoad/UIKit]/Fixture.AutoInstrumentTabViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentTabViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentTabViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentTabViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentTabViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentTabViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentTabViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentTabViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentTabViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.AutoInstrumentTabViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentTabViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentTabViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentTabViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentTabViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentTabViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentTabViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentTabViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentTabViewLoadScenario_SubViewController"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.view.name" equals "Fixture.ViewController"
    * a span string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentTabViewLoadScenario_SubViewController"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" is false
    * a span string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: AutoInstrumentNavigationViewLoadScenario
    Given I run "AutoInstrumentNavigationViewLoadScenario"
    And I wait for 2 seconds
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
    * no span field "name" equals "[ViewLoad/UIKit]/Fixture.AutoInstrumentNavigationViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentNavigationViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentNavigationViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentNavigationViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentNavigationViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentNavigationViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentNavigationViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentNavigationViewLoadScenario_ViewController"
    * no span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentNavigationViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.AutoInstrumentNavigationViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentNavigationViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentNavigationViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentNavigationViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentNavigationViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentNavigationViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentNavigationViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentNavigationViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentNavigationViewLoadScenario_SubViewController"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.view.name" equals "Fixture.ViewController"
    * a span string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentNavigationViewLoadScenario_SubViewController"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" is false
    * a span string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: AutoInstrumentPreLoadedViewLoadScenario
    Given I run "AutoInstrumentPreLoadedViewLoadScenario"
    And I wait for 28 spans
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
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController (pre-loaded)"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController (pre-loaded)"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span field "name" equals "SubViewController_ChildSpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.view.name" equals "Fixture.ViewController"
    * a span string attribute "bugsnag.view.name" equals "Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController (pre-loaded)"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * a span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController (pre-loaded)" started at the same time as a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController" started at the same time as a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController" started at the same time as a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController" started before a span named "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController"
    * a span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_ViewController (pre-loaded)" started before a span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController (pre-loaded)"
    * a span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController (pre-loaded)" started at the same time as a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController" started at the same time as a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController" started at the same time as a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController" started before a span named "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentPreLoadedViewLoadScenario_SubViewController" started at the same time as a span named "SubViewController_ChildSpan"

  Scenario: ViewDidLoadDoesntTriggerScenario
    Given I run "ViewDidLoadDoesntTriggerScenario"
    And I wait for 17 spans
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
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.ViewDidLoadDoesntTriggerScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.ViewDidLoadDoesntTriggerScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.ViewDidLoadDoesntTriggerScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.ViewDidLoadDoesntTriggerScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.ViewDidLoadDoesntTriggerScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.ViewDidLoadDoesntTriggerScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.ViewDidLoadDoesntTriggerScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.ViewDidLoadDoesntTriggerScenario_ViewController"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.view.name" equals "Fixture.ViewController"
    * a span string attribute "bugsnag.view.name" equals "Fixture.ViewDidLoadDoesntTriggerScenario_ViewController"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span string attribute "bugsnag.view.type" equals "UIKit"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: AutoInstrumentSwiftUIScenario no change
    Given I run "AutoInstrumentSwiftUIScenario"
    And I wait for 3 spans
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
    And I wait for 3 spans
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
    Then I wait for 2 spans
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
    And I wait for 2 spans
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
    And I wait for 2 spans
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
    And I wait for 2 spans
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
    And I wait for 2 spans
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
    And I wait for 2 spans
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

  Scenario: Automatically start a network span that has a parent
    Given I run "AutoInstrumentNetworkWithParentScenario"
    And I wait for 2 seconds
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "parentSpanId" exists
    * a span field "parentSpanId" is greater than 0
    * a span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.url" matches the regex "http://.*:9[0-9]{3}/reflect\?status=200"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * a span field "kind" equals 1
    * a span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" does not exist
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Automatically start a network span that has no parent
    Given I run "AutoInstrumentNetworkNoParentScenario"
    And I wait for 2 seconds
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.url" matches the regex "http://.*:9[0-9]{3}/reflect\?status=200"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * a span field "kind" equals 1
    * a span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" does not exist
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Auto-capture multiple network spans
    Given I run "AutoInstrumentNetworkMultiple"
    And I wait for 10 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Automatically start a network span that is a file:// scheme
    Given I run "AutoInstrumentFileURLRequestScenario"
    Then I should receive no traces

  Scenario: Don't send an auto network span that failed to send
    Given I run "AutoInstrumentNetworkBadAddressScenario"
    # Only the initial command request should be captured.
    Then I wait for 1 span

  Scenario: Automatically start a network span that has a null URL
    Given I run "AutoInstrumentNetworkNullURLScenario"
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.url" matches the regex "http://.*:9[0-9]{3}/reflect\?status=200"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Automatically start a network span triggered by AVAssetDownloadURLSession (must not crash)
    Given I run "AutoInstrumentAVAssetScenario"
    And I wait for 2 seconds
    And I wait for 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * a span field "kind" equals 1
    * a span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.instrumentation_message" matches the regex "Error.*"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" does not exist
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Capture automatic network span before configuration
    Given I run "AutoInstrumentNetworkPreStartScenario"
    And I wait for 2 seconds
    And I wait for exactly 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.url" matches the regex "http://.*:9[0-9]{3}/reflect\?status=200"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Invalidate calls on shared session should be ignored
    Given I run "AutoInstrumentNetworkSharedSessionInvalidateScenario"
    And I wait for exactly 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.url" matches the regex "http://.*:9[0-9]{3}/reflect\?status=200"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Capture automatic network span before configuration (disabled)
    Given I run "AutoInstrumentNetworkPreStartDisabledScenario"
    And I should receive no traces

  Scenario: Make sure OnSpanEnd callbacks also get called for early spans.
    Given I run "EarlySpanOnEndScenario"
    And I wait for exactly 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: ComplexViewScenario
    Given I run "ComplexViewScenario"
    And I wait for 27 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:27"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.ComplexViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/loadView]/Fixture.ComplexViewScenario_TableViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.ComplexViewScenario_TableViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLoad]/Fixture.ComplexViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.ComplexViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillAppear]/Fixture.ComplexViewScenario_TableViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.ComplexViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.ComplexViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.ComplexViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.ComplexViewScenario_TableViewController"
    * a span field "name" equals "[ViewLoadPhase/Subview layout]/Fixture.ComplexViewScenario_TableViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.ComplexViewScenario_TableViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.ComplexViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.ComplexViewScenario_ViewController"
    * a span field "name" equals "[ViewLoadPhase/View appearing]/Fixture.ComplexViewScenario_TableViewController"
    * a span field "name" equals "[ViewLoadPhase/viewDidAppear]/Fixture.ComplexViewScenario_TableViewController"
    * a span field "name" equals "[ViewLoad/UIKit]/Fixture.ComplexViewScenario_TableViewController"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.phase" equals "loadView"
    * a span string attribute "bugsnag.phase" equals "viewDidLoad"
    * a span string attribute "bugsnag.phase" equals "viewWillAppear"
    * a span string attribute "bugsnag.phase" equals "viewDidAppear"
    * a span string attribute "bugsnag.phase" equals "viewWillLayoutSubviews"
    * a span string attribute "bugsnag.phase" equals "viewDidLayoutSubviews"
    * a span string attribute "bugsnag.phase" equals "View appearing"
    * a span string attribute "bugsnag.phase" equals "Subview layout"
    * a span string attribute "bugsnag.span.category" equals "view_load"
    * a span string attribute "bugsnag.span.category" equals "view_load_phase"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: ModifyEarlySpansScenario
    Given I run "ModifyEarlySpansScenario"
    And I wait for exactly 5 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:5"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[AppStart/iOSCold]"
    * a span field "name" equals "[AppStartPhase/App launching - pre main()]"
    * a span field "name" equals "[AppStartPhase/App launching - post main()]"
    * a span field "name" equals "[AppStartPhase/UI init]"
    * a span field "name" equals "[HTTP/GET]"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * a span field "kind" equals 1
    * a span field "kind" equals 3
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "bugsnag.app_start.type" equals "cold"
    * a span string attribute "bugsnag.phase" equals "App launching - pre main()"
    * a span string attribute "bugsnag.phase" equals "App launching - post main()"
    * a span string attribute "bugsnag.phase" equals "UI init"
    * a span string attribute "bugsnag.span.category" equals "app_start"
    * a span string attribute "bugsnag.span.category" equals "app_start_phase"
    * every span bool attribute "bugsnag.span.first_class" does not exist
    * every span string attribute "modifiedOnEnd" equals "yes"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
