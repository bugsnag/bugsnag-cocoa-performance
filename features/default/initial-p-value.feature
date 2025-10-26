Feature: Initial P values

  Scenario: Initial P value of 0
    Given I set the sampling probability for the next traces to "0"
    And I run "InitialPScenario"
    And I wait to receive a sampling request
    * the sampling request "Bugsnag-Span-Sampling" header equals "1:0"
    * the sampling request "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * the sampling request payload field "resourceSpans" is an array with 0 elements
    Then I set the sampling probability for the next traces to "0"
    Then I invoke "step2"
    And I should receive no traces

  Scenario: Initial P value of 1
    Given I set the sampling probability for the next traces to "1"
    And I run "InitialPScenario"
    And I wait to receive a sampling request

    Then the sampling request "Bugsnag-Span-Sampling" header equals "1:0"
    * the sampling request "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"

    Then I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "First"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    Then I discard the oldest trace
    And I invoke "step2"
    And I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "Second"
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
