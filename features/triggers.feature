Feature: Automatic send triggers

  Scenario: BackgroundForegroundScenario
    Given I run "BackgroundForegroundScenario" and discard the initial p-value request
    And I send the app to the background for 2 seconds
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * every span field "name" equals "BackgroundForegroundScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.app.in_foreground" is false
