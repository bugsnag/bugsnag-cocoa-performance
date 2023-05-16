Feature: Sampling

  Scenario: No spans should be sent when samplingProbability is zero
    Given I set the sampling probability to "0.0"
    And I run "SamplingProbabilityZeroScenario" and discard the initial p-value request
    Then I should receive no traces

  Scenario: But if the server changes the probability, we must honor that
    Given I set the sampling probability to "1.0"
    And I run "SamplingProbabilityZeroScenario" and discard the initial p-value request
    And I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "Post-start"
