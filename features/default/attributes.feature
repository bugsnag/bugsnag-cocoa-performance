Feature: Spans with custom attributes

  Scenario: Set attributes in a span
    Given I run "SetAttributesScenario"
    And I wait to receive a span named "SetAttributesScenario"
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span string attribute "a" equals "xyz"
    * every span bool attribute "b" does not exist
    * every span bool attribute "d" does not exist
    * a span array attribute "e" is empty
    * a span array attribute "f" is empty
    * a span array attribute "x" is empty
    * a span array attribute "c" contains the string value "array_0" at index 0
    * a span array attribute "c" contains the integer value 1 at index 1
    * a span array attribute "c" contains the value true at index 2
    * a span array attribute "c" contains the float value 1.5 at index 3

  Scenario: Set attributes in a span with limits set
    Given I run "SetAttributesWithLimitsScenario"
    And I wait to receive a span named "SetAttributesWithLimitsScenario"
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span string attribute "a" equals "1234567890*** 1 CHARS TRUNCATED"
    * a span array attribute "b" contains the integer value 1 at index 0
    * a span array attribute "b" contains the integer value 2 at index 1
    * a span array attribute "b" contains the integer value 3 at index 2
    * a span array attribute "b" contains no value at index 3

  Scenario: Set attributes in a span with an attribute count limit set
    Given I run "SetAttributeCountLimitScenario"
    And I wait to receive a span named "SetAttributeCountLimitScenario"
    * the trace "Bugsnag-Span-Sampling" header matches the regex "^1:\d{1,2}$"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * every span string attribute "a" does not exist