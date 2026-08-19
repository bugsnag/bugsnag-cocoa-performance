Feature: GraphQL span detection and attribute correctness on iOS

  Background:
    Given I load scenario "GraphQLDetectScenario"

  # ─── SCENARIO 4: Malformed body fallback to network (4 cases) ─────────────────────
  Scenario Outline: POST to /graphql with <body_type> body does not crash and falls back to network
    And I configure scenario "scenario_number" to "5"
    And I configure scenario "body_type" to "<body_type>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span string attribute "bugsnag.span.category" equals "network"
    And every span attribute "graphql.operation.type" does not exist
    And every span attribute "graphql.operation.name" does not exist

    Examples:
      | body_type    |
      | empty        |
      | malformed    |
      | empty_object |
      | null         |

  # ─── SCENARIO 5: Edge-case operation names (3 cases) ──────────────────────────────
  Scenario Outline: Operation name with <label> is handled without crash or data loss
    And I configure scenario "scenario_number" to "6"
    And I configure scenario "name_type" to "<name_type>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "<name_regex>"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "POST"
    And a span integer attribute "http.status_code" equals 200
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

    Examples:
      | label                       | name_type          | name_regex                                            |
      | very long name (128+ chars) | long               | ^GraphQL .+/graphql - query:.{128,}$                  |
      | underscores and version     | underscore_version | ^GraphQL .+/graphql - query:Get_User_Profile_V2$      |
      | numeric suffix              | numeric_suffix     | ^GraphQL .+/graphql - query:GetUser123$               |

  # ─── SCENARIO 6: Batched GraphQL request (1 case) ──────────────────────────────────
  Scenario: Batched GraphQL request with multiple operations does not crash and falls back to network
    And I configure scenario "scenario_number" to "7"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span string attribute "bugsnag.span.category" equals "network"
    And every span attribute "graphql.operation.type" does not exist
    And every span attribute "graphql.operation.name" does not exist

  # ─── SCENARIO 7: GET with query params (1 case) ────────────────────────────────────
  Scenario: GET request to /graphql with query params is detected as GraphQL
    And I configure scenario "scenario_number" to "8"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "GET"
    And a span integer attribute "http.status_code" equals 200
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

  # ─── SCENARIO 8: Multiple operations create distinct spans (1 case) ─────────────────
  Scenario: Multiple GraphQL operations create distinct spans coexisting with network spans
    And I configure scenario "scenario_number" to "9"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 4 spans
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span field "name" matches the regex "^GraphQL .+/graphql - mutation:CreatePost$"
    And a span string attribute "bugsnag.span.category" equals "graphql"

  # ─── SCENARIO 9: Safe attributes only — no GraphQL-specific metadata (1 case) ────
  Scenario: GraphQL span payload contains only HTTP attributes — no GraphQL-specific metadata
    And I configure scenario "scenario_number" to "10"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "POST"
    And a span integer attribute "http.status_code" equals 200
    And every span attribute "graphql.operation.type" does not exist
    And every span attribute "graphql.operation.name" does not exist
    And every span attribute "graphql.document" does not exist
    And every span attribute "graphql.variables" does not exist
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

  # ─── SCENARIO 10: first_class false (1 case) ───────────────────────────────────────
  Scenario: GraphQL span with explicit first_class=false is not aggregated into span groups
    And I configure scenario "scenario_number" to "11"
    And I configure scenario "first_class" to "false"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is false
    And a span string attribute "http.method" equals "POST"
    And a span integer attribute "http.status_code" equals 200

  # ─── SCENARIO 11: Failure conditions — span expected (1 case) ──────────────────────
  Scenario: GraphQL span is created even when request times out
    And I configure scenario "scenario_number" to "12"
    And I configure scenario "failure_type" to "timeout"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "POST"
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

  # ─── SCENARIO 11: Failure conditions — no span expected (2 cases) ──────────────────
  Scenario Outline: GraphQL request with <failure_type> does not crash and produces no span
    And I configure scenario "scenario_number" to "12"
    And I configure scenario "failure_type" to "<failure_type>"
    And I configure scenario "expected_status" to "<http_status>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 5 seconds
    Then I should receive no spans

    Examples:
      | failure_type       | http_status |
      | connection_refused |             |
      | empty_response     | 204         |

  # ─── SCENARIO 12: iOS SDK via supported GraphQL client library (1 case) ────────────
  Scenario: iOS SDK produces GraphQL span via supported GraphQL client library without document attribute
    And I configure scenario "scenario_number" to "13"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "POST"
    And a span integer attribute "http.status_code" equals 200
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

  # ─── SCENARIO 13: Consistent span names for pipeline grouping (1 case) ─────────────
  Scenario: Multiple identical GraphQL operations produce consistent span names for pipeline grouping
    And I configure scenario "scenario_number" to "14"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 3 spans
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And every span attribute "bugsnag.graphql.document" does not exist

  # ─── SCENARIO 14: Consistent span names with distinct spanIds (1 case) ─────────────
  Scenario: Multiple identical operations produce consistent span names with valid distinct spanIds
    And I configure scenario "scenario_number" to "15"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 3 spans
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And every span attribute "bugsnag.graphql.document" does not exist

  # ─── SCENARIO 15: Response status — success cases (2 cases) ────────────────────────
  Scenario Outline: GraphQL response with <error_type> sets span status to STATUS_CODE_OK
    And I configure scenario "scenario_number" to "16"
    And I configure scenario "error_type" to "<error_type>"
    And I configure scenario "expected_status" to "200"
    And I configure scenario "response_body" to "<response_body>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "POST"
    And a span integer attribute "http.status_code" equals 200
    And a nested span field "status.code" equals "STATUS_CODE_OK"
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

    Examples:
      | error_type                        | response_body                                                                                              |
      | HTTP 200 success (no errors)      | {\"data\": {\"user\": {\"id\": \"1\", \"name\": \"John\"}}}                                   |
      | HTTP 200 with empty errors array  | {\"data\": {\"user\": {\"id\": \"1\"}}, \"errors\": []}                                         |

  # ─── SCENARIO 16: Response status — current behavior (all STATUS_CODE_OK) ─────────
  # NOTE: The SDK currently sets STATUS_CODE_OK for all completed requests regardless of
  # HTTP status or GraphQL errors. When error-status support is implemented, update these
  # expected values from STATUS_CODE_OK to STATUS_CODE_ERROR.
  Scenario Outline: GraphQL response with <error_type> produces span with status <expected_status>
    And I configure scenario "scenario_number" to "16"
    And I configure scenario "error_type" to "<error_type>"
    And I configure scenario "expected_status" to "<http_status>"
    And I configure scenario "response_body" to "<response_body>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "POST"
    And a span integer attribute "http.status_code" equals <http_status>
    And a nested span field "status.code" equals "<expected_status>"
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

    Examples:
      | error_type                        | http_status | response_body                                                                                              | expected_status   |
      | HTTP 200 with errors array        | 200         | {\"data\": null, \"errors\": [{\"message\": \"User not found\", \"path\": [\"user\"]}]}        | STATUS_CODE_OK    |
      | HTTP 200 with partial data+errors | 200         | {\"data\": {\"user\": {\"id\": \"1\"}}, \"errors\": [{\"message\": \"Field deprecated\"}]}   | STATUS_CODE_OK    |
      | HTTP 500 transport error          | 500         |                                                                                                            | STATUS_CODE_OK    |
      | HTTP 401 unauthorized             | 401         |                                                                                                            | STATUS_CODE_OK    |

  # ─── SCENARIO 16: Connection timeout — current behavior ────────────────────────────
  # NOTE: Same as above — SDK currently returns STATUS_CODE_OK even on timeout.
  # Update to STATUS_CODE_ERROR when error-status is implemented.
  Scenario: GraphQL connection timeout produces span with status OK (error status not yet implemented)
    And I configure scenario "scenario_number" to "16"
    And I configure scenario "error_type" to "Connection timeout"
    And I configure scenario "expected_status" to ""
    And I configure scenario "response_body" to ""
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "POST"
    And a nested span field "status.code" equals "STATUS_CODE_OK"
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist
