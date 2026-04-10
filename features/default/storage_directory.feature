Feature: Storage directory creation behavior
  As the SDK, when the app attempts to create storage directories
  I want the SDK to mark storage disabled and avoid writes/retries accordingly

  Background:
    When I load scenario "StorageDirectoryScenario"

  Scenario: Directory creation succeeds - normal behaviour
    Given the storage swizzle mode is "ok" with 0 attempts
    When I perform startup storage directory creation
    And I request to write file "ok-file.json" with payload "ok-payload"
    Then I wait for 1 second

  Scenario: File write succeeds after successful creation
    Given the storage swizzle mode is "ok" with 0 attempts
    Given startup storage directories exist
    When I request to write file "ok-file.json" with payload "ok-payload"
    Then I wait for 1 second

  Scenario: Directory creation fails at startup - storage disabled flag set
    Given the storage swizzle mode is "always_fail" with 0 attempts
    When I perform startup storage directory creation
    Then I wait for 1 second

  Scenario: Directory creation fails - no subsequent file writes attempted
    Given the storage swizzle mode is "always_fail" with 0 attempts
    When I request to write file "no-write.json" with payload "payload"
    Then I wait for 1 second

  Scenario: Directory creation fails - no repeated directory creation attempts
    Given the storage swizzle mode is "always_fail" with 0 attempts
    When I perform startup storage directory creation
    And I request to write file "retry-check.json" with payload "payload1"
    And I request to write file "retry-check.json" with payload "payload2"
    Then I wait for 1 second

  Scenario: Directory temporarily unavailable then available - one-shot disable
    Given the storage swizzle mode is "fail_once" with 1 attempts
    When I request to write file "temp-recovery.json" with payload "first"
    Given the storage swizzle mode is "ok" with 0 attempts
    When I request to write file "temp-recovery.json" with payload "second"
    Then I wait for 1 second
