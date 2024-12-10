Feature: Automatic instrumentation spans AutoInstrumentGenericViewLoadScenario

  Scenario: AutoInstrumentGenericViewLoadScenario2
    Given I run "AutoInstrumentGenericViewLoadScenario2"
    And I should receive no traces
