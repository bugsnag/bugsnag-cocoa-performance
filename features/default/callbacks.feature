Feature: Setting callbacks

  Scenario: Set OnStart
    Given I run "OnStartCallbackScenario"
    And I wait for exactly 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * a span field "name" equals "OnStartCallbackScenario"
    * a span bool attribute "start_callback_1" is true
    * a span bool attribute "start_callback_2" is true

  Scenario: Set OnEnd
    Given I run "OnEndCallbackScenario"
    And I wait for exactly 3 spans
    * a span field "name" equals "OnEndCallbackScenario"
    
  Scenario: Disabling filesystem IO disables all queue operations and triggers error callback once
    Given I run "DisabledFilesystemIOScenario"
    When the retry queue is initialized
    And the queue operations preStartSetup, sweep, list, get, add, and remove are called
