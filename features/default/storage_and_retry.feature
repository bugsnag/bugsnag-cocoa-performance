Feature: Storage and Retry E2E Scenarios

  Background:
    Given I load scenario "DisabledFilesystemIOScenario"

  Scenario: App starts with non-writable directory
    When I configure scenario "fail_storage" to "true"
    And I start bugsnag
    And I run the loaded scenario
    And I generate a span
    Then the app does not crash
    And the logs contain "failed to prepare storage"


  Scenario: No retries when storage is disabled and network fails
    When I configure scenario "fail_storage" to "true"
    And I start bugsnag
    And I simulate network failure
    And I run the loaded scenario
    And I generate a span
    Then the app does not crash
    And the logs contain "failed to prepare storage"


  Scenario: Retries work with writable directory (control)
    Given I load scenario "RetryScenario"
    When I configure scenario "fail_storage" to "false"
    And I start bugsnag
    And I simulate network failure
    And I run the loaded scenario
    And I generate a span
    And I restore network
    Then the app does not crash


  Scenario: Log-noise and performance sanity with failing directory
    When I configure scenario "fail_storage" to "true"
    And I start bugsnag
    And I run the loaded scenario
    And I generate many spans rapidly
    Then logs are not flooded with file IO errors
    And there is no measurable slowdown compared to baseline
