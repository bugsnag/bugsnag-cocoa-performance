Feature: Automatic send triggers

Scenario: BackgroundForegroundScenario
  Given I run "BackgroundForegroundScenario"
  And I switch to the web browser for 2 seconds
  And I wait to receive at least 1 span
  Then the trace "Content-Type" header equals "application/json"
  * the trace "Bugsnag-Span-Sampling" header equals "1:1"
  * every span field "name" equals "BackgroundForegroundScenario"
  * every span field "kind" equals 1
  * every span bool attribute "bugsnag.app.in_foreground" is false
