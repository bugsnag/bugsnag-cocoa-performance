Feature: Infrastructure checks

  Scenario: Check infrastructure when Bugsnag is never started
    Given I run "InfraCheckNoBugsnagScenario"
    And I wait to receive a reflection

  Scenario: Check infrastructure with minimal Bugsnag activity
    Given I run "InfraCheckMinimalBugsnagScenario"
    And I wait to receive a reflection
    And I wait to receive at least 1 span
