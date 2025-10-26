Feature: Sampling

  Scenario: No spans should be sent when samplingProbability is zero
    Given I set the sampling probability to "0.0"
    And I run "SamplingProbabilityZeroScenario"
    Then I should receive no traces

  Scenario: But if the server changes the probability, we must honor that
    Given I set the sampling probability to "1.0"
    And I run "SamplingProbabilityZeroScenario"
    And I wait for 2 spans
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "Pre-start"
    * a span field "name" equals "Post-start"
    * a span double attribute "bugsnag.sampling.p" equals 1.0
