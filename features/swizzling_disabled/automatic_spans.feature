Feature: Automatic instrumentation spans

  Scenario: AutoInstrumentViewLoadScenario with swizzling disabled
    Given I run "AutoInstrumentViewLoadScenario"
    And I should receive no traces

  Scenario: AutoInstrumentSubViewLoadScenario with swizzling disabled
    Given I run "AutoInstrumentSubViewLoadScenario"
    And I should receive no traces

  Scenario: AutoInstrumentTabViewLoadScenario with swizzling disabled
    Given I run "AutoInstrumentTabViewLoadScenario"
    And I should receive no traces

  Scenario: Automatically start a network span that has a parent with swizzling disabled
    Given I run "AutoInstrumentNetworkWithParentScenario"
    And I wait for exactly 1 span
    * a span field "name" equals "parentSpan"

  Scenario: Auto-capture multiple network spans with swizzling disabled
    Given I run "AutoInstrumentNetworkMultiple"
     And I should receive no traces

  Scenario: Automatically start a network span that is a file:// scheme with swizzling disabled
    Given I run "AutoInstrumentFileURLRequestScenario"
    And I should receive no traces

  Scenario: Don't send an auto network span that failed to send with swizzling disabled
    Given I run "AutoInstrumentNetworkBadAddressScenario"
    And I should receive no traces
