Feature: GraphQL span detection and attribute correctness on iOS

  Scenario: GraphQL detected via configured /graphql path produces correct span
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "1"
    And I configure scenario "url_path" to "/graphql"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a span bool attribute "bugsnag.span.first_class" is true

  # Scenario 1: GraphQL detected via Content-Type
  Scenario: GraphQL detected via Content-Type produces correct span
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "1"
    And I configure scenario "url_path" to "/data"
    And I configure scenario "content_type" to "application/graphql"
    And I configure scenario "body" to "query GetUserProfile { user { id name } }"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/data\] query:GetUserProfile$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a span bool attribute "bugsnag.span.first_class" is true

  # Scenario 1b: GraphQL detected via URL /graphql path
  Scenario: GraphQL detected via URL /graphql path produces correct span
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "1"
    And I configure scenario "detection_method" to "url_path"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"query FetchItems { items { id } }\", \"operationName\": \"FetchItems\"}"
    And I configure scenario "expected_status" to "200"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:FetchItems$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a span bool attribute "bugsnag.span.first_class" is true

  # Scenario 1c: GraphQL detected via URL /api/graphql path
  Scenario: GraphQL detected via URL /api/graphql path produces mutation span
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "1"
    And I configure scenario "detection_method" to "url_path"
    And I configure scenario "url" to "https://api.example.com/api/graphql"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"mutation CreatePost($input: CreatePostInput!) { createPost(input: $input) { id } }\", \"operationName\": \"CreatePost\"}"
    And I configure scenario "expected_status" to "200"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/api/graphql\] mutation:CreatePost$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a span bool attribute "bugsnag.span.first_class" is true

  # Scenario 1d: GraphQL detected via URL /api/v1/graphql path
  Scenario: GraphQL detected via URL /api/v1/graphql path produces subscription span
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "1"
    And I configure scenario "detection_method" to "url_path"
    And I configure scenario "url" to "https://api.example.com/api/v1/graphql"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"subscription OnMessage { message { id text } }\", \"operationName\": \"OnMessage\"}"
    And I configure scenario "expected_status" to "200"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/api/v1/graphql\] subscription:OnMessage$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a span bool attribute "bugsnag.span.first_class" is true

  # Scenario 1e: GraphQL detected via URL /graphql/ with trailing slash
  Scenario: GraphQL detected via URL /graphql/ with trailing slash
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "1"
    And I configure scenario "detection_method" to "url_path"
    And I configure scenario "url" to "https://api.example.com/graphql/"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"query GetProfile { profile { name } }\", \"operationName\": \"GetProfile\"}"
    And I configure scenario "expected_status" to "200"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetProfile$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a span bool attribute "bugsnag.span.first_class" is true

  # Scenario 1f: GraphQL detected via body inspection on non-graphql URL
  Scenario: GraphQL detected via body inspection on custom endpoint
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "1"
    And I configure scenario "detection_method" to "body_inspection"
    And I configure scenario "url" to "https://api.example.com/custom-endpoint"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"mutation UpdateUser($id: ID!) { updateUser(id: $id) { id } }\", \"operationName\": \"UpdateUser\"}"
    And I configure scenario "expected_status" to "200"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/custom-endpoint\] mutation:UpdateUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a span bool attribute "bugsnag.span.first_class" is true

  # Scenario 1g: GraphQL span created on HTTP 400 error
  Scenario: GraphQL span created on HTTP 400 error
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "1"
    And I configure scenario "detection_method" to "url_path"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"query BadQuery { invalid }\", \"operationName\": \"BadQuery\"}"
    And I configure scenario "expected_status" to "400"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:BadQuery$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 1h: GraphQL span created on HTTP 401 unauthorized
  Scenario: GraphQL span created on HTTP 401 unauthorized
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "1"
    And I configure scenario "detection_method" to "url_path"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"query GetSecret { secret { value } }\", \"operationName\": \"GetSecret\"}"
    And I configure scenario "expected_status" to "401"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetSecret$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 1i: GraphQL span created on HTTP 500 server error
  Scenario: GraphQL span created on HTTP 500 server error
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "1"
    And I configure scenario "detection_method" to "url_path"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"mutation FailOp { fail { msg } }\", \"operationName\": \"FailOp\"}"
    And I configure scenario "expected_status" to "500"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] mutation:FailOp$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 2: Operation type extraction - operationName field priority (P1)
  Scenario: Operation type query extracted with operationName field priority
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "2"
    And I configure scenario "body" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 2b: Mutation type extracted with operationName field priority
  Scenario: Operation type mutation extracted with operationName field priority
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "2"
    And I configure scenario "body" to "{\"query\": \"mutation CreatePost { createPost { id } }\", \"operationName\": \"CreatePost\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] mutation:CreatePost$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 2c: Subscription type extracted with operationName field priority
  Scenario: Operation type subscription extracted with operationName field priority
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "2"
    And I configure scenario "body" to "{\"query\": \"subscription OnMsg { message { id } }\", \"operationName\": \"OnMsg\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] subscription:OnMsg$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 2d: Document parsing fallback (P2) when no operationName field
  Scenario: Operation name extracted from document parsing when operationName field absent
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "2"
    And I configure scenario "body" to "{\"query\": \"query FetchOrders { orders { id total } }\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:FetchOrders$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 2e: Anonymous query defaults to query type
  Scenario: Anonymous query defaults to query type with empty name
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "2"
    And I configure scenario "body" to "{\"query\": \"{ user { id name } }\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\]$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 2f: operationName field overrides document name
  Scenario: operationName field overrides document-parsed name
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "2"
    And I configure scenario "body" to "{\"query\": \"query DocumentName { user { id } }\", \"operationName\": \"FieldName\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:FieldName$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    
  # Scenario 2g: Mutation extracted from document parsing (P2, no operationName field)
  Scenario: Mutation operation name extracted from document parsing when operationName field absent
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "2"
    And I configure scenario "body" to "{\"query\": \"mutation DeleteItem { deleteItem { success } }\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] mutation:DeleteItem$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    
  # Scenario 2h: Query type present but no operation name
  Scenario: Query type present with no operation name produces span with type only
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "2"
    And I configure scenario "body" to "{\"query\": \"query { user { id } }\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 3: Display name format validation - query with name
  Scenario: Display name follows correct format for query with name
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "3"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "body" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 3b: Display name format - mutation with name
  Scenario: Display name follows correct format for mutation with name
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "3"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "body" to "{\"query\": \"mutation UpdateCart { cart { id } }\", \"operationName\": \"UpdateCart\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] mutation:UpdateCart$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 3c: Display name format - subscription with name
  Scenario: Display name follows correct format for subscription with name
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "3"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "body" to "{\"query\": \"subscription OnNotify { notify { id } }\", \"operationName\": \"OnNotify\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] subscription:OnNotify$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 3d: Display name format - anonymous query (no name, omit parens)
  Scenario: Display name for anonymous query omits operation name
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "3"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "body" to "{\"query\": \"query { user { id } }\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 3e: Display name format - unknown type with known operationName
  Scenario: Display name for unknown type with known operationName
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "3"
    And I configure scenario "url" to "https://api.example.com/graphql"
    And I configure scenario "body" to "{\"query\": \"{ user { id } }\", \"operationName\": \"GetUser\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 3f: Display name format - custom endpoint path
  Scenario: Display name for custom endpoint path
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "3"
    And I configure scenario "url" to "https://api.example.com/api/graphql"
    And I configure scenario "body" to "{\"query\": \"query GetUser { user { id } }\", \"operationName\": \"GetUser\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/api/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 4: Non-GraphQL REST POST retains network category
  Scenario: Non-GraphQL REST POST retains network category
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "4"
    And I configure scenario "http_method" to "POST"
    And I configure scenario "url" to "https://api.example.com/rest/users"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"userId\": \"123\", \"action\": \"get\"}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "network"
    * every span attribute "graphql.operation.type" does not exist
    * every span attribute "graphql.operation.name" does not exist

  # Scenario 4b: JSON with "query" key that is not GraphQL retains network category
  Scenario: JSON with query key that is not GraphQL retains network category
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "4"
    And I configure scenario "http_method" to "POST"
    And I configure scenario "url" to "https://api.example.com/api/search"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"shoes\", \"page\": 1}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "network"

  # Scenario 4c: GET to REST endpoint retains network category
  Scenario: GET to REST endpoint retains network category
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "4"
    And I configure scenario "http_method" to "GET"
    And I configure scenario "url" to "https://api.example.com/api/users/123"
    And I configure scenario "content_type" to "application/json"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "network"

  # Scenario 4d: Natural language query body retains network category
  Scenario: Natural language query body retains network category
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "4"
    And I configure scenario "http_method" to "POST"
    And I configure scenario "url" to "https://api.example.com/api/search"
    And I configure scenario "content_type" to "application/json"
    And I configure scenario "body" to "{\"query\": \"find all users named John\", \"limit\": 10}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "network"

  # Scenario 4e: XML content type retains network category
  Scenario: XML content type retains network category
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "4"
    And I configure scenario "http_method" to "POST"
    And I configure scenario "url" to "https://api.example.com/api/data"
    And I configure scenario "content_type" to "application/xml"
    And I configure scenario "body" to "<request><query>GetUser</query></request>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "network"

  # Scenario 4f: text/html content type retains network category
  Scenario: text/html content type retains network category
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "4"
    And I configure scenario "http_method" to "POST"
    And I configure scenario "url" to "https://api.example.com/submit"
    And I configure scenario "content_type" to "text/html"
    And I configure scenario "body" to "<html><body>test</body></html>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "network"

  # Scenario 5: Malformed body does not crash - empty string
  Scenario: POST to graphql with empty body does not crash and falls back to network
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "5"
    And I configure scenario "body_type" to "empty"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "network"

  # Scenario 5b: Malformed body does not crash - malformed JSON
  Scenario: POST to graphql with malformed JSON does not crash and falls back to network
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "5"
    And I configure scenario "body_type" to "malformed"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "network"

  # Scenario 5c: Malformed body does not crash - empty JSON object
  Scenario: POST to graphql with empty JSON object does not crash and falls back to network
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "5"
    And I configure scenario "body_type" to "empty_object"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "network"

  # Scenario 5d: Malformed body does not crash - null body
  Scenario: POST to graphql with null body does not crash and falls back to network
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "5"
    And I configure scenario "body_type" to "null"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "network"

  # Scenario 6: Edge-case operation names - very long name
  Scenario: Very long operation name does not crash
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "6"
    And I configure scenario "name_type" to "long"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 6b: Edge-case operation names - underscore and version suffix
  Scenario: Operation name with underscores and version suffix is handled
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "6"
    And I configure scenario "name_type" to "underscore_version"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:Get_User_Profile_V2$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 6c: Edge-case operation names - numeric suffix
  Scenario: Operation name with numeric suffix is handled
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "6"
    And I configure scenario "name_type" to "numeric_suffix"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser123$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 7: Batched GraphQL request does not crash
  Scenario: Batched GraphQL request with multiple operations does not crash
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "7"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "network"

  # Scenario 8: GET request with query params
  Scenario: GET request to graphql with query params is detected as GraphQL
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "8"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 9: Multiple operations create distinct spans
  Scenario: Multiple GraphQL operations create distinct spans coexisting with network spans
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "9"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 4 spans
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 10: Span payload contains only safe attributes
  Scenario: GraphQL span does not contain sensitive GraphQL-specific metadata
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "10"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a span bool attribute "bugsnag.span.first_class" is true
    * every span attribute "bugsnag.graphql.document" does not exist
    * every span attribute "bugsnag.graphql.variables" does not exist
    * every span attribute "graphql.operation.type" does not exist
    * every span attribute "graphql.operation.name" does not exist

  # Scenario 11: GraphQL span with first_class false is not aggregated
  Scenario: GraphQL span with first_class false is not aggregated into span groups
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "11"
    And I configure scenario "first_class" to "false"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a span bool attribute "bugsnag.span.first_class" is false

  # Scenario 12: GraphQL span created on request timeout
  Scenario: GraphQL span is created even when request times out
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "12"
    And I configure scenario "failure_type" to "timeout"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 12b: GraphQL span on connection refused
  Scenario: GraphQL request with connection refused does not crash and produces no span
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "12"
    And I configure scenario "failure_type" to "connection_refused"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 5 seconds
    Then I should receive no spans

  # Scenario 12c: 204 empty body - SDK does not produce span (by design)
  Scenario: GraphQL request with 204 empty body does not crash
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "12"
    And I configure scenario "failure_type" to "empty_response"
    And I configure scenario "expected_status" to "204"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 5 seconds
    Then I should receive no spans

  # Scenario 13: iOS URLSession GraphQL request
  Scenario: iOS SDK produces GraphQL span from URLSession request without document attribute
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "13"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * every span attribute "bugsnag.graphql.document" does not exist

  # Scenario 14: Consistent span names for pipeline grouping
  Scenario: Multiple identical operations produce consistent span names for pipeline grouping
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "14"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 3 spans
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    
  # Scenario 15: Multiple identical GraphQL operations produce spans with consistent name for pipeline grouping
  Scenario: Multiple identical operations produce consistent span names with valid distinct spanIds
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "15"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 3 spans
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"

  # Scenario 16: GraphQL 200 response with errors array sets span status to error
  Scenario: GraphQL 200 response with errors array sets span status to error
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "16"
    And I configure scenario "error_type" to "errors_array"
    And I configure scenario "expected_status" to "200"
    And I configure scenario "response_body" to "{\"data\": null, \"errors\": [{\"message\": \"User not found\", \"path\": [\"user\"]}]}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a nested span field "status.code" equals "STATUS_CODE_ERROR"

  # Scenario 16b: GraphQL 200 with partial data + errors sets span status to error
  Scenario: GraphQL 200 response with partial data and errors sets span status to error
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "16"
    And I configure scenario "error_type" to "partial_data_errors"
    And I configure scenario "expected_status" to "200"
    And I configure scenario "response_body" to "{\"data\": {\"user\": {\"id\": \"1\"}}, \"errors\": [{\"message\": \"Field deprecated\"}]}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a nested span field "status.code" equals "STATUS_CODE_ERROR"

  # Scenario 16c: GraphQL 200 success with no errors sets span status to OK
  Scenario: GraphQL 200 response with no errors sets span status to OK
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "16"
    And I configure scenario "error_type" to "success"
    And I configure scenario "expected_status" to "200"
    And I configure scenario "response_body" to "{\"data\": {\"user\": {\"id\": \"1\", \"name\": \"John\"}}}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a nested span field "status.code" equals "STATUS_CODE_OK"

  # Scenario 16d: GraphQL 200 with empty errors array sets span status to OK
  Scenario: GraphQL 200 response with empty errors array sets span status to OK
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "16"
    And I configure scenario "error_type" to "empty_errors"
    And I configure scenario "expected_status" to "200"
    And I configure scenario "response_body" to "{\"data\": {\"user\": {\"id\": \"1\"}}, \"errors\": []}"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a nested span field "status.code" equals "STATUS_CODE_OK"

  # Scenario 16e: HTTP 500 transport error sets span status to error
  Scenario: GraphQL HTTP 500 sets span status to error
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "16"
    And I configure scenario "error_type" to "http_500"
    And I configure scenario "expected_status" to "500"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a nested span field "status.code" equals "STATUS_CODE_ERROR"

  # Scenario 16f: HTTP 401 unauthorized sets span status to error
  Scenario: GraphQL HTTP 401 sets span status to error
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "16"
    And I configure scenario "error_type" to "http_401"
    And I configure scenario "expected_status" to "401"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a nested span field "status.code" equals "STATUS_CODE_ERROR"

  # Scenario 16g: Connection timeout sets span status to error
  Scenario: GraphQL connection timeout sets span status to error
    Given I load scenario "GraphQLDetectScenario"
    And I configure scenario "scenario_number" to "16"
    And I configure scenario "error_type" to "timeout"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" matches the regex "^\[GraphQL\] \[[^\]]*/graphql\] query:GetUser$"
    * a span string attribute "bugsnag.span.category" equals "graphql"
    * a nested span field "status.code" equals "STATUS_CODE_ERROR"
