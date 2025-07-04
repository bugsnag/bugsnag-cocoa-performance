Feature: Plugins

  Scenario: Plugins can automatically update spans
    Given I run "PluginScenario"
    And I wait to receive a sampling request
    And I wait to receive a trace

    Then a span named "Span 1" contains the attributes:
      | attribute    | type      | value |
      | span_count   | intValue  | 1     |
      | plugin_start | boolValue | true  |

    Then a span named "Span 2" contains the attributes:
      | attribute    | type      | value |
      | span_count   | intValue  | 2     |
      | queried      | boolValue | true  |
      | plugin_start | boolValue | true  |

    Then a span named "Span 3" contains the attributes:
      | attribute    | type      | value |
      | span_count   | intValue  | 3     |
      | plugin_start | boolValue | true  |

  Scenario: Error during plugin installation
    Given I run "PluginInstallErrorScenario"
    And I wait to receive a sampling request
    And I wait to receive a trace
    Then every span bool attribute "buggy_span_start" does not exist
    And every span bool attribute "buggy_span_end" does not exist

    And a span named "Span 1" contains the attributes:
      | attribute    | type      | value |
      | span_count   | intValue  | 1     |
      | plugin_start | boolValue | true  |

    And a span named "Span 2" contains the attributes:
      | attribute    | type      | value |
      | span_count   | intValue  | 2     |
      | plugin_start | boolValue | true  |

    And a span named "Span 3" contains the attributes:
      | attribute    | type      | value |
      | span_count   | intValue  | 3     |
      | plugin_start | boolValue | true  |
