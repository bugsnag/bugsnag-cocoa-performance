Feature: Named spans plugin

  Scenario: Spans can be accessed by name using the named spans plugin
    Given I run "NamedSpansPluginScenario"
    And I wait to receive a sampling request
    And I wait to receive a trace

    Then a span named "Test Span" contains the attributes:
      | attribute    | type      | value |
      | queried      | boolValue | true  |
