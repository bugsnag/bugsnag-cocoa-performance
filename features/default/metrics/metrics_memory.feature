Feature: Spans with collected memory metrics

  Scenario: With default settings, memory metrics are disabled
    Given I load scenario "MemoryMetricsScenario"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0"
    And I configure scenario "variant_name" to "DefaultSettings"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * a span field "name" equals "MemoryMetricsScenarioDefaultSettings"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span attribute "bugsnag.system.memory.timestamps" does not exist
    * every span attribute "bugsnag.system.memory.spaces.device.size" does not exist
    * every span attribute "bugsnag.system.memory.spaces.device.used" does not exist
    * every span attribute "bugsnag.system.memory.spaces.device.mean" does not exist

  Scenario: First class spans produce memory metrics
    Given I load scenario "MemoryMetricsScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "variant_name" to "FirstClass"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * a span field "name" equals "MemoryMetricsScenarioFirstClass"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span array attribute "bugsnag.system.memory.timestamps" contains 2 elements
    * a span integer attribute "bugsnag.system.memory.spaces.device.size" is greater than 0
    * a span array attribute "bugsnag.system.memory.spaces.device.used" contains 2 elements
    * a span integer attribute "bugsnag.system.memory.spaces.device.mean" is greater than 0

  Scenario: Non-first-class spans don't produce memory metrics
    Given I load scenario "MemoryMetricsScenario"
    And I configure bugsnag "memoryMetrics" to "false"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0"
    And I configure scenario "opts_first_class" to "no"
    And I configure scenario "variant_name" to "NonFirstClass"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * a span field "name" equals "MemoryMetricsScenarioNonFirstClass"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is false
    * every span attribute "bugsnag.system.memory.timestamps" does not exist
    * every span attribute "bugsnag.system.memory.spaces.device.size" does not exist
    * every span attribute "bugsnag.system.memory.spaces.device.used" does not exist
    * every span attribute "bugsnag.system.memory.spaces.device.mean" does not exist

  Scenario: When memory metrics opts are enabled, we produce memory metrics even if not first class
    Given I load scenario "MemoryMetricsScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0"
    And I configure scenario "opts_first_class" to "no"
    And I configure scenario "opts_metrics_memory" to "yes"
    And I configure scenario "variant_name" to "NonFirstClassEnabled"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * a span field "name" equals "MemoryMetricsScenarioNonFirstClassEnabled"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is false
    * a span array attribute "bugsnag.system.memory.timestamps" contains 2 elements
    * a span integer attribute "bugsnag.system.memory.spaces.device.size" is greater than 0
    * a span array attribute "bugsnag.system.memory.spaces.device.used" contains 2 elements
    * a span integer attribute "bugsnag.system.memory.spaces.device.mean" is greater than 0

  Scenario: Longer span duration captures more memory samples
    Given I load scenario "MemoryMetricsScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "variant_name" to "LongerDuration"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * a span field "name" equals "MemoryMetricsScenarioLongerDuration"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span array attribute "bugsnag.system.memory.timestamps" contains from 3 to 4 elements
    * a span integer attribute "bugsnag.system.memory.spaces.device.size" is greater than 0
    * a span array attribute "bugsnag.system.memory.spaces.device.used" contains from 3 to 4 elements
    * a span integer attribute "bugsnag.system.memory.spaces.device.mean" is greater than 0

  Scenario: If we generate spans later, we still expect memory samples
    Given I load scenario "MemoryMetricsScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "run_delay" to "1.1"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "variant_name" to "GenerateLater"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * a span field "name" equals "MemoryMetricsScenarioGenerateLater"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span array attribute "bugsnag.system.memory.timestamps" contains from 3 to 4 elements
    * a span integer attribute "bugsnag.system.memory.spaces.device.size" is greater than 0
    * a span array attribute "bugsnag.system.memory.spaces.device.used" contains from 3 to 4 elements
    * a span integer attribute "bugsnag.system.memory.spaces.device.mean" is greater than 0
