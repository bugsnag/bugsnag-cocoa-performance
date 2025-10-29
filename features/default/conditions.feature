Feature: Conditions

  Scenario: Manually creating and ending conditions
    Given I run "ConditionsBasicScenario"
    And I wait to receive a span named "ConditionsBasicScenario"
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Integrity" header matches the regex "^sha1 [A-Fa-f0-9]{40}$"
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "ConditionsBasicScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span string attribute "bugsnag.span.category" equals "custom"
    * a span named "ConditionsBasicScenario" duration is equal or greater than 1.0

  Scenario: Span can be blocked again after being ended as long as it is still blocked
    Given I run "ConditionsBlockingBlockedEndedSpanScenario"
    And I wait to receive a span named "ConditionsBlockingBlockedEndedSpanScenario"
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Integrity" header matches the regex "^sha1 [A-Fa-f0-9]{40}$"
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "ConditionsBlockingBlockedEndedSpanScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span string attribute "bugsnag.span.category" equals "custom"
    * a span named "ConditionsBlockingBlockedEndedSpanScenario" duration is equal or greater than 2.0

  Scenario: Condition should not override endTime to an earlier time
    Given I run "ConditionsOverrideEndTimeBackwardsScenario"
    And I wait to receive a span named "ConditionsOverrideEndTimeBackwardsScenario"
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Integrity" header matches the regex "^sha1 [A-Fa-f0-9]{40}$"
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "name" equals "ConditionsOverrideEndTimeBackwardsScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span string attribute "bugsnag.span.category" equals "custom"
    * a span named "ConditionsOverrideEndTimeBackwardsScenario" duration is equal or greater than 1.0

  Scenario: Span Conditions - condition closed
    Given I run "SpanConditionsSimpleConditionScenario"
    And I wait to receive a span named "SpanConditionsSimpleConditionScenarioSpan1"
    And I wait to receive a span named "SpanConditionsSimpleConditionScenarioSpan2"
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span named "SpanConditionsSimpleConditionScenarioSpan1" ended after a span named "SpanConditionsSimpleConditionScenarioSpan2"
    * a span named "SpanConditionsSimpleConditionScenarioSpan2" is a child of span named "SpanConditionsSimpleConditionScenarioSpan1"

  Scenario: Span Conditions - condition timed out
    Given I run "SpanConditionsConditionTimedOutScenario"
    And I wait to receive a span named "SpanConditionsConditionTimedOutScenarioSpan1"
    And I wait to receive a span named "SpanConditionsConditionTimedOutScenarioSpan2"
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span named "SpanConditionsConditionTimedOutScenarioSpan1" ended before a span named "SpanConditionsConditionTimedOutScenarioSpan2" started

  Scenario: Span Conditions - multiple conditions
    Given I run "SpanConditionsMultipleConditionsScenario"
    And I wait to receive a span named "SpanConditionsMultipleConditionsScenarioSpan1"
    And I wait to receive a span named "SpanConditionsMultipleConditionsScenarioSpan2"
    And I wait to receive a span named "SpanConditionsMultipleConditionsScenarioSpan3"
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span named "SpanConditionsMultipleConditionsScenarioSpan3" ended after a span named "SpanConditionsMultipleConditionsScenarioSpan2"
    * a span named "SpanConditionsMultipleConditionsScenarioSpan1" ended after a span named "SpanConditionsMultipleConditionsScenarioSpan3"

  Scenario: Span Conditions - blocking blocked ended span
    Given I run "SpanConditionsBlockedSpanScenario"
    And I wait to receive a span named "SpanConditionsBlockedSpanScenarioSpan1"
    And I wait to receive a span named "SpanConditionsBlockedSpanScenarioSpan2"
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * a span named "SpanConditionsBlockedSpanScenarioSpan1" ended after a span named "SpanConditionsBlockedSpanScenarioSpan2"
