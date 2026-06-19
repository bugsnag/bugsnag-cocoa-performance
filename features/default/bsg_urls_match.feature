Feature: BSGURLsMatchSchemeHostPortPath behavior

Scenario Outline: URLs that should match the configured traces endpoint (network span should be skipped)
    Given I run "BSGURLsMatchScenario"
    And I start bugsnag
    And I invoke "runCase:" with parameter "<case>"
    And I wait to receive at least 1 span
    Then no span string attribute "http.url" matches the regex ".*\/traces.*"

Examples:
    | case           |
    | trailing_slash |
    | query          |
    | scheme_case    |
    | host_case      |

Scenario Outline: URLs that should NOT match the configured traces endpoint (network span should be recorded)
    Given I run "BSGURLsMatchScenario"
    And I start bugsnag
    And I invoke "runCase:" with parameter "<case>"
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    And I wait to receive a span where the string attribute "http.url" matches the regex ".*bsg_case=different_path.*"

Examples:
    | case           |
    | different_path |
