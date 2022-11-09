Feature: Sampling

  Scenario: No spans should be sent when samplingProbability is zero
    Given I set the sampling probability to "0.0"
    And I run "SamplingProbabilityZeroScenario"
    Then I should receive no traces
