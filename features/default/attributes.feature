Feature: Spans with custom attributes

  Scenario: Set attributes in a span
    Given I run "SetAttributesScenario"
    And I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "SetAttributesScenario"
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
    And I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "SetAttributesWithLimitsScenario"
    * a span string attribute "a" equals "1234567890*** 1 CHARS TRUNCATED"
    * a span array attribute "b" contains the integer value 1 at index 0
    * a span array attribute "b" contains the integer value 2 at index 1
    * a span array attribute "b" contains the integer value 3 at index 2
    * a span array attribute "b" contains no value at index 3

  Scenario: Set attributes in a span with an attribute count limit set
    Given I run "SetAttributeCountLimitScenario"
    And I wait for 1 span
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "SetAttributeCountLimitScenario"
    * every span string attribute "a" does not exist