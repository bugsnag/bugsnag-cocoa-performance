Feature: GraphQL span detection and attribute correctness on iOS

  Background:
    Given I load scenario "GraphQLDetectScenario"

  # ─── SCENARIO 1: Detection produces correct span with full attributes (10 cases) ─────────────
  Scenario Outline: GraphQL detected via <detection_method> produces correct span with full attributes
    And I configure scenario "scenario_number" to "1"
    And I configure scenario "detection_method" to "<detection_method>"
    And I configure scenario "url" to "<url>"
    And I configure scenario "content_type" to "<content_type>"
    And I configure scenario "body" to "<body>"
    And I configure scenario "expected_status" to "<status>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "<name_regex>"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "POST"
    And a span integer attribute "http.status_code" equals <status>
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist
    And every span attribute "graphql.operation.type" does not exist
    And every span attribute "graphql.operation.name" does not exist

    Examples:
      | detection_method                  | url                                          | content_type        | body                                                                                                                                          | status | name_regex                                               |
      | url_path (/graphql + JSON body)   | https://api.example.com/graphql              | application/json    | {\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}                                                                | 200    | ^GraphQL .+/graphql - query:GetUser$                     |
      | Content-Type (application/graphql)| https://api.example.com/data                 | application/graphql | query GetUserProfile { user { id name } }                                                                                                     | 200    | ^GraphQL .+/data - query:GetUserProfile$                 |
      | url_path (/graphql)               | https://api.example.com/graphql              | application/json    | {\"query\": \"query FetchItems { items { id } }\", \"operationName\": \"FetchItems\"}                                                         | 200    | ^GraphQL .+/graphql - query:FetchItems$                  |
      | url_path (/api/graphql)           | https://api.example.com/api/graphql          | application/json    | {\"query\": \"mutation CreatePost($input: CreatePostInput!) { createPost(input: $input) { id } }\", \"operationName\": \"CreatePost\"}         | 200    | ^GraphQL .+/api/graphql - mutation:CreatePost$           |
      | url_path (/api/v1/graphql)        | https://api.example.com/api/v1/graphql       | application/json    | {\"query\": \"subscription OnMessage { message { id text } }\", \"operationName\": \"OnMessage\"}                                             | 200    | ^GraphQL .+/api/v1/graphql - subscription:OnMessage$     |
      | url_path (/graphql/ trailing)     | https://api.example.com/graphql/             | application/json    | {\"query\": \"query GetProfile { profile { name } }\", \"operationName\": \"GetProfile\"}                                                     | 200    | ^GraphQL .+/graphql/? - query:GetProfile$                |
      | body_inspection (custom URL)      | https://api.example.com/custom-endpoint      | application/json    | {\"query\": \"mutation UpdateUser($id: ID!) { updateUser(id: $id) { id } }\", \"operationName\": \"UpdateUser\"}                              | 200    | ^GraphQL .+/custom-endpoint - mutation:UpdateUser$       |
      | url_path (HTTP 400 error)         | https://api.example.com/graphql              | application/json    | {\"query\": \"query BadQuery { invalid }\", \"operationName\": \"BadQuery\"}                                                                  | 400    | ^GraphQL .+/graphql - query:BadQuery$                    |
      | url_path (HTTP 401 unauthorized)  | https://api.example.com/graphql              | application/json    | {\"query\": \"query GetSecret { secret { value } }\", \"operationName\": \"GetSecret\"}                                                      | 401    | ^GraphQL .+/graphql - query:GetSecret$                   |
      | url_path (HTTP 500 server error)  | https://api.example.com/graphql              | application/json    | {\"query\": \"mutation FailOp { fail { msg } }\", \"operationName\": \"FailOp\"}                                                              | 500    | ^GraphQL .+/graphql - mutation:FailOp$                   |

  # ─── SCENARIO 2: Operation type/name extraction (8 cases) ─────────────────────────────────────
  Scenario Outline: Operation type <op_type> correctly extracted via <priority>
    And I configure scenario "scenario_number" to "2"
    And I configure scenario "body" to "<body>"
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
    And every span attribute "graphql.operation.type" does not exist
    And every span attribute "graphql.operation.name" does not exist

    Examples:
      | priority                         | op_type      | body                                                                                                   | name_regex                                    |
      | operationName field (P1)         | query        | {\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}                         | ^GraphQL .+/graphql - query:GetUser$          |
      | operationName field (P1)         | mutation     | {\"query\": \"mutation CreatePost { createPost { id } }\", \"operationName\": \"CreatePost\"}          | ^GraphQL .+/graphql - mutation:CreatePost$    |
      | operationName field (P1)         | subscription | {\"query\": \"subscription OnMsg { message { id } }\", \"operationName\": \"OnMsg\"}                   | ^GraphQL .+/graphql - subscription:OnMsg$     |
      | document parsing (P2)            | query        | {\"query\": \"query FetchOrders { orders { id total } }\"}                                             | ^GraphQL .+/graphql - query:FetchOrders$      |
      | anonymous (P3, no type or name)  | (anonymous)  | {\"query\": \"{ user { id name } }\"}                                                                  | ^GraphQL .+/graphql$                          |
      | operationName overrides doc name | query        | {\"query\": \"query DocumentName { user { id } }\", \"operationName\": \"FieldName\"}                  | ^GraphQL .+/graphql - query:FieldName$        |
      | document parsing (P2)            | mutation     | {\"query\": \"mutation DeleteItem { deleteItem { success } }\"}                                        | ^GraphQL .+/graphql - mutation:DeleteItem$    |
      | type present, name absent        | query        | {\"query\": \"query { user { id } }\"}                                                                 | ^GraphQL .+/graphql - query$                  |

  # ─── SCENARIO 3: Span name format validation (6 cases) ────────────────────────
  Scenario Outline: Span name follows correct format for <description>
    And I configure scenario "scenario_number" to "3"
    And I configure scenario "url" to "<url>"
    And I configure scenario "body" to "<body>"
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
      | description                      | url                                     | body                                                                                                   | name_regex                                    |
      | query with name                  | https://api.example.com/graphql         | {\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}                         | ^GraphQL .+/graphql - query:GetUser$          |
      | mutation with name               | https://api.example.com/graphql         | {\"query\": \"mutation UpdateCart { cart { id } }\", \"operationName\": \"UpdateCart\"}                 | ^GraphQL .+/graphql - mutation:UpdateCart$     |
      | subscription with name           | https://api.example.com/graphql         | {\"query\": \"subscription OnNotify { notify { id } }\", \"operationName\": \"OnNotify\"}              | ^GraphQL .+/graphql - subscription:OnNotify$  |
      | anonymous query (no name)        | https://api.example.com/graphql         | {\"query\": \"query { user { id } }\"}                                                                 | ^GraphQL .+/graphql - query$                  |
      | unknown type with operationName  | https://api.example.com/graphql         | {\"query\": \"{ user { id } }\", \"operationName\": \"GetUser\"}                                       | ^GraphQL .+/graphql - query:GetUser$          |
      | custom endpoint path             | https://api.example.com/api/graphql     | {\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}                         | ^GraphQL .+/api/graphql - query:GetUser$      |

  # ─── SCENARIO 4: Non-GraphQL requests retain network category (6 cases) ──────────────────────
  Scenario Outline: Non-GraphQL <case> request retains network category
    And I configure scenario "scenario_number" to "4"
    And I configure scenario "http_method" to "<http_method>"
    And I configure scenario "url" to "<url>"
    And I configure scenario "content_type" to "<content_type>"
    And I configure scenario "body" to "<body>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span string attribute "bugsnag.span.category" equals "network"
    And a span field "name" does not match the regex "^GraphQL.*"
    And every span attribute "graphql.operation.type" does not exist
    And every span attribute "graphql.operation.name" does not exist
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

    Examples:
      | case                              | http_method | url                                    | content_type     | body                                                             |
      | Standard REST POST                | POST        | https://api.example.com/rest/users     | application/json | {\"userId\": \"123\", \"action\": \"get\"}                       |
      | JSON with query key (not GraphQL) | POST        | https://api.example.com/api/search     | application/json | {\"query\": \"shoes\", \"page\": 1}                              |
      | GET to REST endpoint              | GET         | https://api.example.com/api/users/123  | application/json |                                                                  |
      | Natural language query body       | POST        | https://api.example.com/api/search     | application/json | {\"query\": \"find all users named John\", \"limit\": 10}        |
      | XML content type                  | POST        | https://api.example.com/api/data       | application/xml  | <request><query>GetUser</query></request>                        |
      | text/html content type            | POST        | https://api.example.com/submit         | text/html        | <html><body>test</body></html>                                   |

  # ─── SCENARIO 5: Malformed body fallback to network (4 cases) ─────────────────────────────────
  Scenario Outline: POST to /graphql with <body_label> does not crash and falls back to network
    And I configure scenario "scenario_number" to "5"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "<body>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span string attribute "bugsnag.span.category" equals "network"
    And a span field "name" does not match the regex "^GraphQL.*"
    And every span attribute "graphql.operation.type" does not exist
    And every span attribute "graphql.operation.name" does not exist
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

    Examples:
      | body_label        | body           |
      | empty string      |                |
      | malformed JSON    | {invalid json  |
      | empty JSON object | {}             |
      | null value        | null           |

  # ─── SCENARIO 6: Edge-case operation names (3 cases) ──────────────────────────
  Scenario Outline: Operation name with <label> is handled without crash or data loss
    And I configure scenario "scenario_number" to "6"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "body" to "<body>"
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
      | label                       | name_regex                               | body                                                                                                   |
      | very long name (128+ chars) | ^GraphQL .+ - query:.{128,}$             | __long_128__                                                                                           |
      | underscores and version     | ^GraphQL .+ - query:Get_User_Profile_V2$ | {\"query\": \"query Get_User_Profile_V2 { user { id } }\", \"operationName\": \"Get_User_Profile_V2\"} |
      | numeric suffix              | ^GraphQL .+ - query:GetUser123$          | {\"query\": \"query GetUser123 { user { id } }\", \"operationName\": \"GetUser123\"}                   |
      
  # ─── SCENARIO 7: Batched GraphQL request (1 case) ─────────────────────────────
  Scenario: Batched GraphQL request with multiple operations does not crash and falls back to network
    And I configure scenario "scenario_number" to "7"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "[{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}, {\"query\": \"query GetPosts { posts { id } }\", \"operationName\": \"GetPosts\"}]"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span string attribute "bugsnag.span.category" equals "network"
    And a span field "name" does not match the regex "^GraphQL.*"
    And a span integer attribute "http.status_code" equals 200
    And every span attribute "graphql.operation.type" does not exist
    And every span attribute "graphql.operation.name" does not exist
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

  # ─── SCENARIO 8: GET with query params (1 case) ──────────────────────────────
  Scenario: GET request to /graphql with query params is detected as GraphQL
    And I configure scenario "scenario_number" to "8"
    And I configure scenario "http_method" to "GET"
    And I configure scenario "url" to "https://api.example.com/graphql?query={user{id}}&operationName=GetUser"
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

  # ─── SCENARIO 9: Multiple operations create distinct spans (1 case) ──────────
  Scenario: Multiple GraphQL operations create distinct spans coexisting with network spans
    And I configure scenario "scenario_number" to "9"
    And I configure scenario "graphql_body_1" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I configure scenario "graphql_body_2" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I configure scenario "graphql_body_3" to "{\"query\": \"mutation CreatePost { createPost { id } }\", \"operationName\": \"CreatePost\"}"
    And I configure scenario "rest_url" to "https://api.example.com/rest/users/123"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 4 spans
    # 2 GraphQL query spans
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    # 1 GraphQL mutation span
    And a span field "name" matches the regex "^GraphQL .+/graphql - mutation:CreatePost$"
    # 1 Network span (REST GET)
    And a span string attribute "bugsnag.span.category" equals "network"
    # GraphQL spans have correct attributes
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span integer attribute "http.status_code" equals 200
    # No sensitive data leaked
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

  # ─── SCENARIO 10: Safe attributes only — no sensitive GraphQL metadata (1 case) ─
  Scenario: GraphQL span payload contains only HTTP attributes — no sensitive GraphQL metadata leaked
    And I configure scenario "scenario_number" to "10"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"query GetUser($id: ID!) { user(id: $id) { id name email sensitiveData } }\", \"operationName\": \"GetUser\", \"variables\": {\"id\": \"user_secret_123\"}}"
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
    And no span attribute value contains "user_secret_123"
    And no span attribute value contains "sensitiveData"

  # ─── SCENARIO 11: first_class false (1 case) ─────────────────────────────────────────────────
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

  # ─── SCENARIO 12: Failure conditions — span expected on timeout ────────────────
  Scenario: GraphQL span is created even when request times out
    And I configure scenario "scenario_number" to "12"
    And I configure scenario "failure_type" to "timeout"
    And I configure scenario "body" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "POST"
    And a span field "startTimeUnixNano" is greater than 0
    And a span field "endTimeUnixNano" is greater than 0
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

  # ─── SCENARIO 12: Failure conditions — no span expected (2 cases) ──────────────
  Scenario Outline: GraphQL request <failure_type> does not crash and produces no span
    And I configure scenario "scenario_number" to "12"
    And I configure scenario "failure_type" to "<failure_type>"
    And I configure scenario "body" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 5 seconds
    Then I should receive no spans

    Examples:
      | failure_type       |
      | connection_refused |
      | empty_body         |

  # ─── SCENARIO 14: iOS GraphQL client library — mutation (1 case) ───────────────
  Scenario: iOS SDK produces GraphQL span for mutation via URLSession without document attribute
    And I configure scenario "scenario_number" to "14"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"mutation UpdateCart($id: ID!) { updateCart(id: $id) { total } }\", \"variables\": {\"id\": \"cart_456\"}, \"operationName\": \"UpdateCart\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^GraphQL .+/graphql - mutation:UpdateCart$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "POST"
    And a span integer attribute "http.status_code" equals 200
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist
    And no span attribute value contains "cart_456"

  # ─── SCENARIO 15: Consistent span names with distinct IDs (1 case) ─────────────
  Scenario: Multiple identical GraphQL operations produce consistent span names with valid distinct spanIds
    And I configure scenario "scenario_number" to "15"
    And I configure scenario "graphql_body_1" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I configure scenario "graphql_body_2" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I configure scenario "graphql_body_3" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 3 spans
    # All 3 spans must have the same consistent name
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span integer attribute "http.status_code" equals 200
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist
    # Each span must have a valid spanId and traceId
    And every span field "spanId" exists
    And every span field "traceId" exists
    # All 3 spanIds must be distinct (no duplicate spans)
    And every span has a distinct field "spanId"

  # ─── SCENARIO 16: Response status — all cases combined (7 cases) ─────────────────────────────
  Scenario Outline: GraphQL response with <label> sets span status to <expected_status_code>
    And I configure scenario "scenario_number" to "16"
    And I configure scenario "error_type" to "<error_type>"
    And I configure scenario "expected_status" to "<http_status>"
    And I configure scenario "response_body" to "<response_body>"
    And I configure scenario "body" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^GraphQL .+/graphql - query:GetUser$"
    And a span string attribute "bugsnag.span.category" equals "graphql"
    And a span bool attribute "bugsnag.span.first_class" is true
    And a span string attribute "http.method" equals "POST"
    And a nested span field "status.code" equals "<expected_status_code>"
    And every span attribute "bugsnag.graphql.document" does not exist
    And every span attribute "bugsnag.graphql.variables" does not exist

    Examples:
      | label                             | error_type          | http_status | response_body                                                                                         | expected_status_code |
      | HTTP 200 success (no errors)      | success             | 200         | {\"data\": {\"user\": {\"id\": \"1\", \"name\": \"John\"}}}                                          | STATUS_CODE_OK       |
      | HTTP 200 with empty errors []     | empty_errors        | 200         | {\"data\": {\"user\": {\"id\": \"1\"}}, \"errors\": []}                                              | STATUS_CODE_OK       |
      | HTTP 200 with errors array        | errors_array        | 200         | {\"data\": null, \"errors\": [{\"message\": \"User not found\", \"path\": [\"user\"]}]}              | STATUS_CODE_ERROR    |
      | HTTP 200 with partial data+errors | partial_data_errors | 200         | {\"data\": {\"user\": {\"id\": \"1\"}}, \"errors\": [{\"message\": \"Field deprecated\"}]}           | STATUS_CODE_ERROR    |
      | HTTP 500 transport error          | http_500            | 500         |                                                                                                       | STATUS_CODE_ERROR    |
      | HTTP 401 unauthorized             | http_401            | 401         |                                                                                                       | STATUS_CODE_ERROR    |
      | Connection timeout                | timeout             |             |                                                                                                       | STATUS_CODE_ERROR    |
