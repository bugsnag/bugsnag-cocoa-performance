Feature: Automatic app start instrumentation spans

  Scenario: Auto instrument app starts without a view load
    Given I run "AutoInstrumentAppStartsScenario"
    Then I relaunch the app after shutdown
    And I wait to receive a span named "[AppStart/iOSCold]"
    And I wait to receive a span named "[AppStartPhase/App launching - pre main()]"
    And I wait to receive a span named "[AppStartPhase/App launching - post main()]"
    And I wait to receive a span named "[AppStartPhase/UI init]"
    Then the trace "Content-Type" header equals "application/json"
    * every span field "kind" equals 1
    * a span string attribute "bugsnag.app_start.type" equals "cold"
    * a span string attribute "bugsnag.phase" equals "App launching - pre main()"
    * a span string attribute "bugsnag.phase" equals "App launching - post main()"
    * a span string attribute "bugsnag.phase" equals "UI init"
    * a span string attribute "bugsnag.span.category" equals "app_start"
    * a span string attribute "bugsnag.span.category" equals "app_start_phase"
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.cpu_measures_total" is not empty
    * the span named "[AppStart/iOSCold]" float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.cpu_measures_main_thread" is not empty
    * the span named "[AppStart/iOSCold]" float attribute "bugsnag.system.cpu_mean_main_thread" is greater than 0.0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.cpu_measures_overhead" is not empty
    * the span named "[AppStart/iOSCold]" float attribute "bugsnag.system.cpu_mean_overhead" is greater than 0.0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.memory.timestamps" is not empty
    * the span named "[AppStart/iOSCold]" integer attribute "bugsnag.system.memory.spaces.device.size" is greater than 0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.memory.spaces.device.used" is not empty
    * the span named "[AppStart/iOSCold]" integer attribute "bugsnag.system.memory.spaces.device.mean" is greater than 0
    * a span bool attribute "bugsnag.span.first_class" is true
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"

  Scenario: Auto instrument app starts with a view load
    Given I run "AutoInstrumentAppStartsWithViewLoadScenario"
    Then I relaunch the app after shutdown
    And I wait to receive a span named "[AppStart/iOSCold]"
    And I wait to receive a span named "[AppStartPhase/App launching - pre main()]"
    And I wait to receive a span named "[AppStartPhase/App launching - post main()]"
    And I wait to receive a span named "[AppStartPhase/UI init]"
    And I wait to receive a span named "[ViewLoad/UIKit]/Fixture.ViewController"
    And I wait to receive a span named "[ViewLoadPhase/loadView]/Fixture.ViewController"
    And I wait to receive a span named "[ViewLoadPhase/viewDidLoad]/Fixture.ViewController"
    And I wait to receive a span named "[ViewLoadPhase/viewWillAppear]/Fixture.ViewController"
    And I wait to receive a span named "[ViewLoadPhase/View appearing]/Fixture.ViewController"
    And I wait to receive a span named "[ViewLoadPhase/viewDidAppear]/Fixture.ViewController"
    And I wait to receive a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.ViewController"
    And I wait to receive a span named "[ViewLoadPhase/Subview layout]/Fixture.ViewController"
    And I wait to receive a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.ViewController"
    Then the trace "Content-Type" header equals "application/json"
    * every span field "kind" equals 1
    * a span string attribute "bugsnag.app_start.type" equals "cold"
    * a span string attribute "bugsnag.phase" equals "App launching - pre main()"
    * a span string attribute "bugsnag.phase" equals "App launching - post main()"
    * a span string attribute "bugsnag.phase" equals "UI init"
    * a span string attribute "bugsnag.span.category" equals "app_start"
    * a span string attribute "bugsnag.span.category" equals "app_start_phase"
    * a span bool attribute "bugsnag.span.first_class" is true
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.cpu_measures_total" is not empty
    * the span named "[AppStart/iOSCold]" float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.cpu_measures_main_thread" is not empty
    * the span named "[AppStart/iOSCold]" float attribute "bugsnag.system.cpu_mean_main_thread" is greater than 0.0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.cpu_measures_overhead" is not empty
    * the span named "[AppStart/iOSCold]" float attribute "bugsnag.system.cpu_mean_overhead" is greater than 0.0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.memory.timestamps" is not empty
    * the span named "[AppStart/iOSCold]" integer attribute "bugsnag.system.memory.spaces.device.size" is greater than 0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.memory.spaces.device.used" is not empty
    * the span named "[AppStart/iOSCold]" integer attribute "bugsnag.system.memory.spaces.device.mean" is greater than 0
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * a span named "[ViewLoad/UIKit]/Fixture.ViewController" is a child of span named "[AppStartPhase/UI init]"
    * a span named "[ViewLoadPhase/loadView]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/viewDidAppear]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.ViewController"
    * a span named "[AppStart/iOSCold]" ended at the same time as a span named "[AppStartPhase/UI init]"
    * a span named "[ViewLoad/UIKit]/Fixture.ViewController" ended before a span named "[AppStartPhase/UI init]"

  Scenario: Auto instrument app starts with a loading indicator
    Given I run "AutoInstrumentAppStartsLoadingScenario"
    Then I relaunch the app after shutdown
    And I wait to receive a span named "[AppStart/iOSCold]"
    And I wait to receive a span named "[AppStartPhase/App launching - pre main()]"
    And I wait to receive a span named "[AppStartPhase/App launching - post main()]"
    And I wait to receive a span named "[AppStartPhase/UI init]"
    And I wait to receive a span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    And I wait to receive a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    And I wait to receive a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    And I wait to receive a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    And I wait to receive a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    And I wait to receive a span named "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    And I wait to receive a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    And I wait to receive a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    And I wait to receive a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    And I wait to receive a span named "[ViewLoadPhase/viewDataLoading]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    Then the trace "Content-Type" header equals "application/json"
    * every span field "kind" equals 1
    * a span string attribute "bugsnag.app_start.type" equals "cold"
    * a span string attribute "bugsnag.phase" equals "App launching - pre main()"
    * a span string attribute "bugsnag.phase" equals "App launching - post main()"
    * a span string attribute "bugsnag.phase" equals "UI init"
    * a span string attribute "bugsnag.span.category" equals "app_start"
    * a span string attribute "bugsnag.span.category" equals "app_start_phase"
    * a span bool attribute "bugsnag.span.first_class" is true
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.cpu_measures_total" is not empty
    * the span named "[AppStart/iOSCold]" float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.cpu_measures_main_thread" is not empty
    * the span named "[AppStart/iOSCold]" float attribute "bugsnag.system.cpu_mean_main_thread" is greater than 0.0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.cpu_measures_overhead" is not empty
    * the span named "[AppStart/iOSCold]" float attribute "bugsnag.system.cpu_mean_overhead" is greater than 0.0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.memory.timestamps" is not empty
    * the span named "[AppStart/iOSCold]" integer attribute "bugsnag.system.memory.spaces.device.size" is greater than 0
    * the span named "[AppStart/iOSCold]" array attribute "bugsnag.system.memory.spaces.device.used" is not empty
    * the span named "[AppStart/iOSCold]" integer attribute "bugsnag.system.memory.spaces.device.mean" is greater than 0
    * the span named "[AppStart/iOSCold]" integer attribute "bugsnag.rendering.total_frames" is greater than 0
    * the span named "[AppStart/iOSCold]" integer attribute "bugsnag.rendering.slow_frames" exists
    * the span named "[AppStart/iOSCold]" integer attribute "bugsnag.rendering.frozen_frames" exists
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * a span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController" is a child of span named "[AppStartPhase/UI init]"
    * a span named "[ViewLoadPhase/loadView]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLoad]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillAppear]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    * a span named "[ViewLoadPhase/View appearing]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidAppear]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    * a span named "[ViewLoadPhase/viewWillLayoutSubviews]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    * a span named "[ViewLoadPhase/Subview layout]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    * a span named "[ViewLoadPhase/viewDidLayoutSubviews]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController" is a child of span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController"
    * a span named "[AppStart/iOSCold]" ended at the same time as a span named "[AppStartPhase/UI init]"
    * a span named "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartsLoadingScenario_ViewController" ended at the same time as a span named "[AppStartPhase/UI init]"

  Scenario: Auto instrument app startup with interrupted view load
    Given I run "AppStartInterruptedScenario"
    Then I relaunch the app after shutdown
    And I wait to receive a span named "AppStartInterruptedScenario"
    * no span field "name" equals "[AppStart/iOSCold]"
    * no span field "name" equals "[ViewLoad/UIKit]/Fixture.AutoInstrumentAppStartInterruptedScenario_ViewController"

  Scenario: Auto instrument legacy app startup 
    Given I run "AppStartLegacyScenario"
    Then I relaunch the app after shutdown
  #  And I wait for 4 seconds
  #  And I relaunch the app after shutdown
    And I wait to receive a span named "[AppStart/iOSCold]"
    And I wait to receive a span named "[AppStartPhase/App launching - pre main()]"
    And I wait to receive a span named "[AppStartPhase/App launching - post main()]"
    And I wait to receive a span named "[AppStartPhase/UI init]"
    And I wait to receive a span named "[ViewLoad/UIKit]/Fixture.AppStartLegacyScenario_ViewController"
    * a span named "[AppStart/iOSCold]" ended before a span named "[ViewLoad/UIKit]/Fixture.AppStartLegacyScenario_ViewController"
    * a span named "[AppStart/iOSCold]" ended at the same time as a span named "[AppStartPhase/UI init]"

  Scenario: Auto instrument legacy app startup with delayed BugsnagPerformance start
    Given I run "AppStartLegacyDelayedStartScenario"
    Then I relaunch the app after shutdown
    And I wait to receive a span named "[AppStart/iOSCold]"
    And I wait to receive a span named "[AppStartPhase/App launching - pre main()]"
    And I wait to receive a span named "[AppStartPhase/App launching - post main()]"
    And I wait to receive a span named "[AppStartPhase/UI init]"
    And I wait to receive a span named "[ViewLoad/UIKit]/Fixture.AppStartLegacyDelayedStartScenario_ViewController"
    * a span named "[AppStart/iOSCold]" ended before a span named "[ViewLoad/UIKit]/Fixture.AppStartLegacyDelayedStartScenario_ViewController"
    * a span named "[AppStart/iOSCold]" ended at the same time as a span named "[AppStartPhase/UI init]"

  Scenario: Auto instrument legacy app startup with BugsnagPerformance start called after app startup ended
    Given I run "AppStartLegacyStartAfterAppStartScenario"
    Then I relaunch the app after shutdown
    And I wait to receive a span named "[AppStart/iOSCold]"
    And I wait to receive a span named "[AppStartPhase/App launching - pre main()]"
    And I wait to receive a span named "[AppStartPhase/App launching - post main()]"
    And I wait to receive a span named "[AppStartPhase/UI init]"
    And I wait to receive a span named "[ViewLoad/UIKit]/Fixture.AppStartLegacyStartAfterAppStartScenario_ViewController"
    * a span named "[AppStart/iOSCold]" ended before a span named "[ViewLoad/UIKit]/Fixture.AppStartLegacyStartAfterAppStartScenario_ViewController"
    * a span named "[AppStart/iOSCold]" ended at the same time as a span named "[AppStartPhase/UI init]"

  Scenario: Auto instrument legacy app startup with interrupted view load
    Given I run "AppStartLegacyInterruptedScenario"
    Then I relaunch the app after shutdown
    And I wait to receive a span named "[AppStart/iOSCold]"

