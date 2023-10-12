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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

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
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

  Scenario: Automatically start a network span that has a parent
    Given I run "AutoInstrumentNetworkWithParentScenario"
    And I wait for 2 seconds
    And I wait for 3 spans
    # Discard the request to http://bs-local.com:9339/command
    And I discard the oldest trace
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "parentSpanId" exists
    * a span field "parentSpanId" is greater than 0
    * a span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.url" matches the regex "http://.*:9340/reflect/"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" does not exist
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

  Scenario: Automatically start a network span that has no parent
    Given I run "AutoInstrumentNetworkNoParentScenario"
    And I wait for 2 seconds
    And I wait for 3 spans
    # Discard the request to http://bs-local.com:9339/command
    And I discard the oldest trace
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.flavor" exists
    * a span string attribute "http.url" matches the regex "http://.*:9340/reflect/"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0
    * a span string attribute "net.host.connection.type" equals "wifi"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span bool attribute "bugsnag.span.first_class" does not exist
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

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
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" equals "com.bugsnag.fixtures.PerformanceFixture"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]\.[0-9]\.[0-9]"

  Scenario: Automatically start a network span that is a file:// scheme
    Given I run "AutoInstrumentFileURLRequestScenario"
    And I wait for 2 seconds
    And I wait for 1 span
    # We should only see the request to http://bs-local.com:9339/command, not the file:// request
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "parentSpanId" exists
    * a span field "parentSpanId" is greater than 0
    * a span field "parentSpanId" does not exist
    * a span field "name" equals "[HTTP/GET]"
    * a span string attribute "http.url" matches the regex "http://.*:9339/command"
    * a span string attribute "http.method" equals "GET"
    * a span integer attribute "http.status_code" is greater than 0
    * a span integer attribute "http.response_content_length" is greater than 0

  Scenario: Don't send an auto network span that failed to send
    Given I run "AutoInstrumentNetworkBadAddressScenario"
    # Only the initial command request should be captured.
    Then I wait for 1 span
