Feature: Initial P values

  Scenario: Initial P value of 0
    Given I set the sampling probability for the next traces to "0"
    And I run "InitialPScenario"
    And I wait to receive a sampling request
    * the sampling request "Bugsnag-Span-Sampling" header equals "1:0"
    * the sampling request "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the sampling request payload field "resourceSpans" is an array with 0 elements

  Scenario: Initial P value of 1
    Given I set the sampling probability for the next traces to "1"
    And I run "InitialPScenario"
    And I wait to receive a sampling request

    Then the sampling request "Bugsnag-Span-Sampling" header equals "1:0"
    * the sampling request "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"

    Then I wait for 2 spans
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"

    * a span field "name" equals "First"
    * a span field "name" equals "Second"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"

  Scenario: ProbabilityExpiryScenario
    Given I run "ProbabilityExpiryScenario"
    And I wait to receive at least 1 sampling request
    * the sampling request "Bugsnag-Span-Sampling" header equals "1:0"
    * the sampling request "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the sampling request payload field "resourceSpans" is an array with 0 elements
