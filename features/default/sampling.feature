Feature: Sampling

  Scenario: No spans should be sent when samplingProbability is zero
    Given I set the sampling probability to "0.0"
    And I run "SamplingProbabilityZeroScenario"
    Then I should receive no traces

  Scenario: But if the server changes the probability, we must honor that
    Given I set the sampling probability to "1.0"
    And I run "SamplingProbabilityZeroScenario"
    And I wait to receive at least 2 spans
    * the trace "Bugsnag-Span-Sampling" header equals "1:2"
    * a span field "name" equals "Pre-start"
    * a span field "name" equals "Post-start"
    * a span double attribute "bugsnag.sampling.p" equals 1.0

  Scenario: Spans are sent regardless of batch being full if in debug mode
    Given I run "DebugModeScenario"
    And I wait to receive between 59 and 60 spans
    * a span field "name" equals "DebugModeScenario-29"
    * a span field "name" equals "DebugModeScenario-59"
    And the difference between "Bugsnag-Sent-At" of first and last request is at most 5 seconds
