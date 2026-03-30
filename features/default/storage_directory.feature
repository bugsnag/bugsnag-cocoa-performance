Feature: Storage directory creation behavior
  As the SDK, when the app attempts to create storage directories
  I want the SDK to mark storage disabled and avoid writes/retries accordingly

  Background:
    When I load scenario "InfraCheckMinimalBugsnagScenario"

  Scenario: Directory creation succeeds - normal behaviour
    When I invoke "maze_set_swizzle_mode" with parameter "{\"mode\":\"ok\",\"attempts\":0}"
    When I invoke "maze_perform_startup_creation"
    When I invoke "maze_request_write:" with parameter "{\"filename\":\"ok-file.json\",\"payload\":\"ok-payload\"}"

  Scenario: Directory creation fails at startup - storage disabled flag set
    When I invoke "maze_set_swizzle_mode" with parameter "{\"mode\":\"always_fail\",\"attempts\":0}"
    When I invoke "maze_perform_startup_creation"

  Scenario: Directory creation fails - no subsequent file writes attempted
    When I invoke "maze_set_swizzle_mode" with parameter "{\"mode\":\"always_fail\",\"attempts\":0}"
    When I invoke "maze_request_write:" with parameter "{\"filename\":\"no-write.json\",\"payload\":\"payload\"}"

  Scenario: Directory creation fails - no repeated directory creation attempts
    When I invoke "maze_set_swizzle_mode" with parameter "{\"mode\":\"always_fail\",\"attempts\":0}"
    When I invoke "maze_perform_startup_creation"
    When I invoke "maze_request_write:" with parameter "{\"filename\":\"retry-check.json\",\"payload\":\"payload1\"}"
    When I invoke "maze_request_write:" with parameter "{\"filename\":\"retry-check.json\",\"payload\":\"payload2\"}"

  Scenario: Directory temporarily unavailable then available - one-shot disable
    When I invoke "maze_set_swizzle_mode" with parameter "{\"mode\":\"fail_once\",\"attempts\":1}"
    When I invoke "maze_request_write:" with parameter "{\"filename\":\"temp-recovery.json\",\"payload\":\"first\"}"
    When I invoke "maze_set_swizzle_mode" with parameter "{\"mode\":\"ok\",\"attempts\":0}"
    When I invoke "maze_request_write:" with parameter "{\"filename\":\"temp-recovery.json\",\"payload\":\"second\"}"
