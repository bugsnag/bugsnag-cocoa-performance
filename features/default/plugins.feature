Feature: Plugins

  Scenario: Plugins can automatically update spans
    Given I run "PluginScenario"
    And I wait to receive a sampling request
    And I wait to receive a trace

    Then a span named "Span 1" contains the attributes:
      | attribute | type        | value |
      | spanCount | intValue    | 1     |

    Then a span named "Span 2" contains the attributes:
      | attribute | type        | value |
      | spanCount | intValue    | 2     |
      | queried   | boolValue   | true  |

    Then a span named "Span 3" contains the attributes:
      | attribute | type        | value |
      | spanCount | intValue    | 3     |