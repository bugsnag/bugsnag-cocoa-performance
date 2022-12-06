Feature: Initial P values

  Scenario: Initial P value of 0
    Given I set the sampling probability for the next traces to "0"
    And I run "RetryScenario"
    And I wait to receive 1 traces
    * the trace payload field "resourceSpans" is an array with 0 elements

  Scenario: Initial P value of 1
    Given I set the sampling probability for the next traces to "1"
    And I run "RetryScenario"
    And I wait to receive 3 traces
    * the trace payload field "resourceSpans" is an array with 0 elements

