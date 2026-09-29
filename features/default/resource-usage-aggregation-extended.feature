Feature: Foreground App Session Span - Extended Validations

  Scenario: App session span contains all CPU sub-metrics with range validation
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure bugsnag "memoryMetrics" to "false"
    And I configure scenario "session_type" to "CPUSession"
    And I configure scenario "span_duration" to "3.0"
    And I configure scenario "work_duration" to "2.0"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "variant_name" to "CPU"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/CPUSession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * a span bool attribute "bugsnag.span.first_class" is true
    # All CPU sub-metrics exist and > 0
    * span float attribute "bugsnag.system.cpu_mean_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_min_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_max_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_mean_main_thread" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_max_main_thread" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_mean_overhead" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_max_overhead" should be greater than 0.0
    # All CPU attributes < 100
    * span float attribute "bugsnag.system.cpu_mean_total" should be less than 100.0
    * span float attribute "bugsnag.system.cpu_max_total" should be less than 100.0
    * span float attribute "bugsnag.system.cpu_mean_main_thread" should be less than 100.0
    * span float attribute "bugsnag.system.cpu_max_main_thread" should be less than 100.0
    * span float attribute "bugsnag.system.cpu_mean_overhead" should be less than 100.0
    * span float attribute "bugsnag.system.cpu_max_overhead" should be less than 100.0
    # min ≤ mean ≤ max for all CPU fields
    * a span float attribute "bugsnag.system.cpu_min_total" is less than or equal to span float attribute "bugsnag.system.cpu_mean_total"
    * a span float attribute "bugsnag.system.cpu_mean_total" is less than or equal to span float attribute "bugsnag.system.cpu_max_total"
    * a span float attribute "bugsnag.system.cpu_min_main_thread" is less than or equal to span float attribute "bugsnag.system.cpu_mean_main_thread"
    * a span float attribute "bugsnag.system.cpu_mean_main_thread" is less than or equal to span float attribute "bugsnag.system.cpu_max_main_thread"
    * a span float attribute "bugsnag.system.cpu_min_overhead" is less than or equal to span float attribute "bugsnag.system.cpu_mean_overhead"
    * a span float attribute "bugsnag.system.cpu_mean_overhead" is less than or equal to span float attribute "bugsnag.system.cpu_max_overhead"

  Scenario: App session span has first_class true with both metrics enabled
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "session_type" to "full metrics session"
    And I configure scenario "span_duration" to "3.0"
    And I configure scenario "work_duration" to "2.0"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "variant_name" to "MinMeanMax"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/FullMetricsSession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * a span bool attribute "bugsnag.span.first_class" is true
    * span integer attribute "bugsnag.system.memory.spaces.device.mean" should be greater than 0
    * span float attribute "bugsnag.system.cpu_mean_total" should be greater than 0.0

  Scenario: App session span has first_class true even when metrics are disabled
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "false"
    And I configure bugsnag "cpuMetrics" to "false"
    And I configure scenario "session_type" to "disabled metrics"
    And I configure scenario "span_duration" to "2.0"
    And I configure scenario "variant_name" to "MetricsDisabled"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/DisabledMetrics]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * a span bool attribute "bugsnag.span.first_class" is true
    * every span attribute "bugsnag.system.memory.spaces.device.mean" does not exist
    * every span attribute "bugsnag.system.cpu_mean_total" does not exist

  Scenario: Memory allocation during session produces memory max greater than or equal to min
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "false"
    And I configure scenario "session_type" to "memory session"
    And I configure scenario "span_duration" to "3.0"
    And I configure scenario "variant_name" to "Memory"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/MemorySession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * a span bool attribute "bugsnag.span.first_class" is true
    * span integer attribute "bugsnag.system.memory.spaces.device.min" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.mean" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.max" should be greater than 0
    * a span integer attribute "bugsnag.system.memory.spaces.device.min" is less than or equal to span integer attribute "bugsnag.system.memory.spaces.device.mean"
    * a span integer attribute "bugsnag.system.memory.spaces.device.mean" is less than or equal to span integer attribute "bugsnag.system.memory.spaces.device.max"

  Scenario: Very short app session span produces valid metrics within 1 second
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "session_type" to "full metrics session"
    And I configure scenario "span_duration" to "1.0"
    And I configure scenario "work_duration" to "0.8"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "variant_name" to "MinMeanMax"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/FullMetricsSession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * a span bool attribute "bugsnag.span.first_class" is true
    * span integer attribute "bugsnag.system.memory.spaces.device.min" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.mean" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.max" should be greater than 0
    * span float attribute "bugsnag.system.cpu_min_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_mean_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_max_total" should be greater than 0.0
    * a span integer attribute "bugsnag.system.memory.spaces.device.min" is less than or equal to span integer attribute "bugsnag.system.memory.spaces.device.max"
    * a span float attribute "bugsnag.system.cpu_min_total" is less than or equal to span float attribute "bugsnag.system.cpu_max_total"
    
  Scenario: App session span does not parent other spans
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "session_type" to "full metrics session"
    And I configure scenario "span_duration" to "3.0"
    And I configure scenario "work_duration" to "2.0"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "variant_name" to "MinMeanMax"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/FullMetricsSession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span field "parentSpanId" does not exist
