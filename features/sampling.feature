Feature: Sampling

  Scenario: No spans should be sent when samplingProbability is zero
    Given I run "SamplingProbabilityZeroScenario"
    Then I should receive no traces
