Feature: Initial P values

  Scenario: Initial P value of 0
    Given I set the sampling probability for the next traces to "0"
    And I run "InitialPScenario"
    And I wait to receive 1 traces
    * the trace "Bugsnag-Span-Sampling" header equals "1:0"
    * the trace payload field "resourceSpans" is an array with 0 elements

  Scenario: Initial P value of 1
    Given I set the sampling probability for the next traces to "1"
    And I run "InitialPScenario"
    And I wait for 2 spans
    * a span field "name" equals "First"
    * a span field "name" equals "Second"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals "SPAN_KIND_INTERNAL"
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace "Bugsnag-Span-Sampling" header equals "1:0"
    And I discard the oldest trace
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
