Feature: Enabled release stages

  Scenario: No spans should be sent when releaseStage is not one of enabledReleaseStages
    Given I run "ReleaseStageNotEnabledScenario"
    Then I should receive no traces
