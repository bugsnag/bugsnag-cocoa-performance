Feature: Plugins

  Scenario: Plugins can automatically update spans
    Given I run "PluginScenario"
    And I wait to receive a sampling request
    And I wait to receive at least 3 spans

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
    And I wait to receive at least 3 spans
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

  Scenario: App start type plugin correctly changes the span name
    Given I run "AppStartTypeScenario"
    Then I relaunch the app after shutdown
    And I wait to receive at least 5 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[AppStart/iOSCold]customType"

  Scenario: App start type plugin wont change span name if it's too late
    Given I run "AppStartTypeLateScenario"
    Then I relaunch the app after shutdown
    And I wait for 4 seconds
    And I wait to receive at least 5 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "[AppStart/iOSCold]"
