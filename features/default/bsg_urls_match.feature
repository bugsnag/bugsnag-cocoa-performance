Feature: BSGURLsMatchSchemeHostPortPath behavior

Scenario Outline: URLs that should match the configured traces endpoint (network span should be skipped)
  Given I run "BSGURLsMatchScenario"
  And I start bugsnag
  And I invoke "runCase:" with parameter "<case>"
  And I wait to receive at least 1 span
  Then no span string attribute "http.url" matches the regex ".*\/v1\/traces.*"

Examples:
  | case           |
  | trailing_slash |
  | query          |
  | scheme_case    |
  | host_case      |
  | explicit_port  |

Scenario Outline: URLs that should NOT match the configured traces endpoint (network span should be recorded)
  Given I run "BSGURLsMatchScenario"
  And I start bugsnag
  And I invoke "runCase:" with parameter "<case>"
  And I wait to receive at least 1 span
  Then the trace "Content-Type" header equals "application/json"
  And a span string attribute "http.url" matches the regex ".*\/idem-command.*"

Examples:
  | case           |
  | different_path |
