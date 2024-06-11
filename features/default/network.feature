Feature: Automatic instrumentation spans

  Scenario: AutoInstrumentNetworkCallbackScenario
    Given I run "AutoInstrumentNetworkCallbackScenario"
    And I wait for exactly 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "[HTTP/GET]"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "http.url" equals "https://bugsnag.com"
    * a span string attribute "http.url" equals "https://bugsnag.com/changed"

  Scenario: ManualNetworkCallbackScenario
    Given I run "ManualNetworkCallbackScenario"
    And I wait for exactly 2 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "[HTTP/GET]"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span string attribute "http.url" equals "https://bugsnag.com"
    * a span string attribute "http.url" equals "https://bugsnag.com/changed"

  Scenario: AutoInstrumentNetworkTracePropagationScenario: Allow All
    Given I load scenario "AutoInstrumentNetworkTracePropagationScenario"
    And I configure "propagateTraceParentToUrlsMatching" to ".*"
    And I invoke "setCallSitesWithCallSiteStrs:" with parameter "?test=1"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive a reflection
    Then the reflection "traceparent" header matches the regex "^00-[A-Fa-f0-9]{32}-[A-Fa-f0-9]{16}-01"

  Scenario: AutoInstrumentNetworkTracePropagationScenario: Allow None by default
    Given I load scenario "AutoInstrumentNetworkTracePropagationScenario"
    And I invoke "setCallSitesWithCallSiteStrs:" with parameter "?test=1"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive a reflection
    Then the reflection "traceparent" header is not present

  Scenario: AutoInstrumentNetworkTracePropagationScenario: Allow Some
    Given I load scenario "AutoInstrumentNetworkTracePropagationScenario"
    And I configure "propagateTraceParentToUrlsMatching" to ".*test.*"
    And I invoke "setCallSitesWithCallSiteStrs:" with parameter "?test=1,?temp=1"
    And I start bugsnag
    And I run the loaded scenario
    Then I wait to receive 2 reflections
    And the reflection "traceparent" header matches the regex "^00-[A-Fa-f0-9]{32}-[A-Fa-f0-9]{16}-01"
    Then I discard the oldest reflection
    And the reflection "traceparent" header is not present
