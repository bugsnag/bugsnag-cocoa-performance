Feature: Metrics

  Scenario: With default settings, CPU metrics are disabled
    Given I load scenario "CPUMetricsScenario"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "work_duration" to "0"
    And I configure scenario "span_duration" to "0"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span attribute "bugsnag.system.cpu_measures_total" does not exist
    * every span attribute "bugsnag.system.cpu_mean_total" does not exist
    * every span attribute "bugsnag.system.cpu_measures_main_thread" does not exist
    * every span attribute "bugsnag.system.cpu_mean_main_thread" does not exist
    * every span attribute "bugsnag.system.cpu_measures_overhead" does not exist
    * every span attribute "bugsnag.system.cpu_mean_overhead" does not exist

  Scenario: When CPU metrics are disabled, no metrics are produced no matter what
    Given I load scenario "CPUMetricsScenario"
    And I configure bugsnag "cpuMetrics" to "false"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "work_duration" to "0"
    And I configure scenario "span_duration" to "0"
    And I configure scenario "opts_metrics_cpu" to "yes"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span attribute "bugsnag.system.cpu_measures_total" does not exist
    * every span attribute "bugsnag.system.cpu_mean_total" does not exist
    * every span attribute "bugsnag.system.cpu_measures_main_thread" does not exist
    * every span attribute "bugsnag.system.cpu_mean_main_thread" does not exist
    * every span attribute "bugsnag.system.cpu_measures_overhead" does not exist
    * every span attribute "bugsnag.system.cpu_mean_overhead" does not exist

  Scenario: First class spans produce CPU metrics
    Given I load scenario "CPUMetricsScenario"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "work_duration" to "0"
    And I configure scenario "span_duration" to "0"
    And I configure scenario "opts_first_class" to "yes"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span array attribute "bugsnag.system.cpu_measures_total" contains 2 elements
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * a span array attribute "bugsnag.system.cpu_measures_main_thread" contains 2 elements
    * a span float attribute "bugsnag.system.cpu_mean_main_thread" is greater than 0.0
    * a span array attribute "bugsnag.system.cpu_measures_overhead" contains 2 elements
    * a span float attribute "bugsnag.system.cpu_mean_overhead" is greater than 0.0

  Scenario: Non-first-class spans don't produce CPU metrics
    Given I load scenario "CPUMetricsScenario"
    And I configure bugsnag "cpuMetrics" to "false"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "work_duration" to "0"
    And I configure scenario "span_duration" to "0"
    And I configure scenario "opts_first_class" to "no"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is false
    * every span attribute "bugsnag.system.cpu_measures_total" does not exist
    * every span attribute "bugsnag.system.cpu_mean_total" does not exist
    * every span attribute "bugsnag.system.cpu_measures_main_thread" does not exist
    * every span attribute "bugsnag.system.cpu_mean_main_thread" does not exist
    * every span attribute "bugsnag.system.cpu_measures_overhead" does not exist
    * every span attribute "bugsnag.system.cpu_mean_overhead" does not exist

  Scenario: When CPU metrics opts are enabled, we produce CPU metrics even if not first class
    Given I load scenario "CPUMetricsScenario"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "work_duration" to "0"
    And I configure scenario "span_duration" to "0"
    And I configure scenario "opts_first_class" to "no"
    And I configure scenario "opts_metrics_cpu" to "yes"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is false
    * a span array attribute "bugsnag.system.cpu_measures_total" contains 2 elements
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * a span array attribute "bugsnag.system.cpu_measures_main_thread" contains 2 elements
    * a span float attribute "bugsnag.system.cpu_mean_main_thread" is greater than 0.0
    * a span array attribute "bugsnag.system.cpu_measures_overhead" contains 2 elements
    * a span float attribute "bugsnag.system.cpu_mean_overhead" is greater than 0.0

  Scenario: Longer span duration captures more CPU samples
    Given I load scenario "CPUMetricsScenario"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "work_duration" to "0"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "opts_first_class" to "yes"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span array attribute "bugsnag.system.cpu_measures_total" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * a span array attribute "bugsnag.system.cpu_measures_main_thread" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_main_thread" is greater than 0.0
    * a span array attribute "bugsnag.system.cpu_measures_overhead" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_overhead" is greater than 0.0

  Scenario: If we generate spans later, we still expect CPU samples
    Given I load scenario "CPUMetricsScenario"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "run_delay" to "1.1"
    And I configure scenario "work_duration" to "0"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "opts_first_class" to "yes"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span array attribute "bugsnag.system.cpu_measures_total" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * a span float attribute "bugsnag.system.cpu_mean_total" is less than 10.0
    * a span array attribute "bugsnag.system.cpu_measures_main_thread" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_main_thread" is greater than 0.0
    * a span float attribute "bugsnag.system.cpu_mean_main_thread" is less than 10.0
    * a span array attribute "bugsnag.system.cpu_measures_overhead" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_overhead" is greater than 0.0
    * a span float attribute "bugsnag.system.cpu_mean_overhead" is less than 10.0

  Scenario: Do heavy work on the main thread while collecting CPU samples
    Given I load scenario "CPUMetricsScenario"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "run_delay" to "1.1"
    And I configure scenario "work_duration" to "3.0"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "opts_first_class" to "yes"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span array attribute "bugsnag.system.cpu_measures_total" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 50.0
    * a span array attribute "bugsnag.system.cpu_measures_main_thread" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_main_thread" is greater than 50.0
    * a span array attribute "bugsnag.system.cpu_measures_overhead" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_overhead" is greater than 0.0
    * a span float attribute "bugsnag.system.cpu_mean_overhead" is less than 10.0

  Scenario: Do heavy work on a bg thread while collecting CPU samples
    Given I load scenario "CPUMetricsScenario"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "run_delay" to "1.1"
    And I configure scenario "work_duration" to "3.0"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "opts_first_class" to "yes"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span array attribute "bugsnag.system.cpu_measures_total" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 50.0
    * a span array attribute "bugsnag.system.cpu_measures_main_thread" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_main_thread" is greater than 0.0
    * a span float attribute "bugsnag.system.cpu_mean_main_thread" is less than 10.0
    * a span array attribute "bugsnag.system.cpu_measures_overhead" contains from 3 to 4 elements
    * a span float attribute "bugsnag.system.cpu_mean_overhead" is greater than 0.0
    * a span float attribute "bugsnag.system.cpu_mean_overhead" is less than 10.0

  Scenario: With default settings, memory metrics are disabled
    Given I load scenario "MemoryMetricsScenario"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
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
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
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
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
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
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
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
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
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
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * the trace "Bugsnag-Sent-At" header matches the regex "^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ$"
    * a span field "name" equals "MySpan"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span field "startTimeUnixNano" matches the regex "^[0-9]+$"
    * every span field "endTimeUnixNano" matches the regex "^[0-9]+$"
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.version" matches the regex "[0-9]+\.[0-9]+\.[0-9]+"
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span array attribute "bugsnag.system.memory.timestamps" contains from 3 to 4 elements
    * a span integer attribute "bugsnag.system.memory.spaces.device.size" is greater than 0
    * a span array attribute "bugsnag.system.memory.spaces.device.used" contains from 3 to 4 elements
    * a span integer attribute "bugsnag.system.memory.spaces.device.mean" is greater than 0
