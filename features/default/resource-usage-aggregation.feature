Feature: Foreground App Session Span

Scenario: App session span sends app-session attributes
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "false"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "TestManualSpan"

Scenario: App session span contains memory aggregate attributes
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "session_type" to "memory session"
    And I configure scenario "span_duration" to "2.5"
    And I configure scenario "variant_name" to "Memory"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/MemorySession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * a span bool attribute "bugsnag.span.first_class" is true
    * span integer attribute "bugsnag.system.memory.spaces.device.size" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.mean" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.min" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.max" should be greater than 0
    

Scenario: App session span contains CPU aggregate attributes
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure bugsnag "memoryMetrics" to "false"
    And I configure scenario "session_type" to "CPUSession"
    And I configure scenario "span_duration" to "4.0"
    And I configure scenario "work_duration" to "3.0"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "variant_name" to "CPU"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/CPUSession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * span float attribute "bugsnag.system.cpu_mean_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_min_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_max_total" should be greater than 0.0

Scenario: App session type is sanitized
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "session_type" to "user checkout-flow"
    And I configure scenario "span_duration" to "2.0"
    And I configure scenario "variant_name" to "Sanitized"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/UserCheckoutFlow]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * a span string attribute "bugsnag.app_session.name" equals "UserCheckoutFlow"

Scenario: App session span does not contain resource usage when metrics are disabled
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
    * every span attribute "bugsnag.system.memory.spaces.device.mean" does not exist
    * every span attribute "bugsnag.system.memory.spaces.device.min" does not exist
    * every span attribute "bugsnag.system.memory.spaces.device.max" does not exist
    * every span attribute "bugsnag.system.cpu_mean_total" does not exist
    * every span attribute "bugsnag.system.cpu_min_total" does not exist
    * every span attribute "bugsnag.system.cpu_max_total" does not exist

Scenario: Normal custom span is not treated as app session span
    Given I load scenario "MemoryMetricsScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "variant_name" to "CustomRegression"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "MemoryMetricsScenarioCustomRegression"
    * every span string attribute "bugsnag.span.category" equals "custom"
    * every span attribute "bugsnag.app_session.name" does not exist
    * span integer attribute "bugsnag.system.memory.spaces.device.mean" should be greater than 0
    * every span attribute "bugsnag.system.memory.spaces.device.min" does not exist
    * every span attribute "bugsnag.system.memory.spaces.device.max" does not exist
    * every span attribute "bugsnag.system.cpu_min_total" does not exist
    * every span attribute "bugsnag.system.cpu_max_total" does not exist

Scenario: Aborted app session span is not sent
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "session_type" to "aborted session"
    And I configure scenario "span_duration" to "1.0"
    And I configure scenario "abort_span" to "true"
    And I configure scenario "variant_name" to "Aborted"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 5 seconds

Scenario: Force-terminated app session span is not sent
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "session_type" to "force killed session"
    And I configure scenario "span_duration" to "30.0"
    And I configure scenario "variant_name" to "ForceKilled"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for 3 seconds
    And I close the app
    And I wait for 5 seconds
    Then I should receive no spans

Scenario: CPU and memory aggregates satisfy min ≤ mean ≤ max
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
    * span integer attribute "bugsnag.system.memory.spaces.device.min" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.mean" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.max" should be greater than 0
    * span float attribute "bugsnag.system.cpu_min_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_mean_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_max_total" should be greater than 0.0
    * a span integer attribute "bugsnag.system.memory.spaces.device.min" is less than or equal to span integer attribute "bugsnag.system.memory.spaces.device.mean"
    * a span integer attribute "bugsnag.system.memory.spaces.device.mean" is less than or equal to span integer attribute "bugsnag.system.memory.spaces.device.max"
    * a span float attribute "bugsnag.system.cpu_min_total" is less than or equal to span float attribute "bugsnag.system.cpu_mean_total"
    * a span float attribute "bugsnag.system.cpu_mean_total" is less than or equal to span float attribute "bugsnag.system.cpu_max_total"

Scenario: Single sample produces min equals max equals mean
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "session_type" to "single sample session"
    And I configure scenario "span_duration" to "0.1"
    And I configure scenario "work_duration" to "0.05"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "variant_name" to "SingleSample"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/SingleSampleSession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * span integer attribute "bugsnag.system.memory.spaces.device.min" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.mean" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.max" should be greater than 0
    * span float attribute "bugsnag.system.cpu_min_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_mean_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_max_total" should be greater than 0.0
    * a span integer attribute "bugsnag.system.memory.spaces.device.min" is less than or equal to span integer attribute "bugsnag.system.memory.spaces.device.max"
    * a span float attribute "bugsnag.system.cpu_min_total" is less than or equal to span float attribute "bugsnag.system.cpu_max_total"

Scenario: CPU disabled but memory enabled produces CPU absent and memory present
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "false"
    And I configure scenario "session_type" to "memory only session"
    And I configure scenario "span_duration" to "2.5"
    And I configure scenario "variant_name" to "MemoryOnly"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/MemoryOnlySession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * span integer attribute "bugsnag.system.memory.spaces.device.mean" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.min" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.max" should be greater than 0
    * every span attribute "bugsnag.system.cpu_mean_total" does not exist
    * every span attribute "bugsnag.system.cpu_min_total" does not exist
    * every span attribute "bugsnag.system.cpu_max_total" does not exist

Scenario: Memory disabled but CPU enabled produces memory absent and CPU present
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure bugsnag "memoryMetrics" to "false"
    And I configure scenario "session_type" to "cpu only session"
    And I configure scenario "span_duration" to "2.5"
    And I configure scenario "work_duration" to "2.0"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "variant_name" to "CPUOnly"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/CpuOnlySession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * span float attribute "bugsnag.system.cpu_mean_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_min_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_max_total" should be greater than 0.0
    * every span attribute "bugsnag.system.memory.spaces.device.mean" does not exist
    * every span attribute "bugsnag.system.memory.spaces.device.min" does not exist
    * every span attribute "bugsnag.system.memory.spaces.device.max" does not exist

Scenario: App session span contains all CPU sub-metrics
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure bugsnag "memoryMetrics" to "false"
    And I configure scenario "session_type" to "CPUSubMetricsSession"
    And I configure scenario "span_duration" to "3.0"
    And I configure scenario "work_duration" to "2.5"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "variant_name" to "CPUSubMetrics"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/CPUSubMetricsSession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * span float attribute "bugsnag.system.cpu_mean_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_min_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_max_total" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_mean_main_thread" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_max_main_thread" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_mean_overhead" should be greater than 0.0
    * span float attribute "bugsnag.system.cpu_max_overhead" should be greater than 0.0
    * a span float attribute "bugsnag.system.cpu_min_total" is less than or equal to span float attribute "bugsnag.system.cpu_mean_total"
    * a span float attribute "bugsnag.system.cpu_min_main_thread" is less than or equal to span float attribute "bugsnag.system.cpu_mean_main_thread"
    * a span float attribute "bugsnag.system.cpu_min_overhead" is less than or equal to span float attribute "bugsnag.system.cpu_mean_overhead"
    * span float attribute "bugsnag.system.cpu_mean_total" should be less than 100.0
    * span float attribute "bugsnag.system.cpu_mean_main_thread" should be less than 100.0
    * span float attribute "bugsnag.system.cpu_mean_overhead" should be less than 100.0
    

Scenario: Two concurrent app sessions deliver independently with separate metrics
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "session_type" to "concurrent session A"
    And I configure scenario "concurrent_session_type" to "concurrent session B"
    And I configure scenario "span_duration" to "3.0"
    And I configure scenario "work_duration" to "2.0"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "variant_name" to "Concurrent"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 2 spans
    Then a span field "name" equals "[AppSession/ConcurrentSessionA]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * span integer attribute "bugsnag.system.memory.spaces.device.mean" should be greater than 0
    * span float attribute "bugsnag.system.cpu_mean_total" should be greater than 0.0
    And a span field "name" equals "[AppSession/ConcurrentSessionB]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * span integer attribute "bugsnag.system.memory.spaces.device.mean" should be greater than 0
    * span float attribute "bugsnag.system.cpu_mean_total" should be greater than 0.0

Scenario: High CPU load during session produces higher cpu_max_total
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure bugsnag "memoryMetrics" to "false"
    And I configure scenario "session_type" to "high cpu load session"
    And I configure scenario "span_duration" to "3.0"
    And I configure scenario "work_duration" to "2.5"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "variant_name" to "HighCPU"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/HighCpuLoadSession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * span float attribute "bugsnag.system.cpu_mean_total" should be greater than 1.0

Scenario: Memory allocation during session produces higher memory max than min
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "false"
    And I configure scenario "session_type" to "memory allocation session"
    And I configure scenario "span_duration" to "3.0"
    And I configure scenario "variant_name" to "MemoryAllocation"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "[AppSession/MemoryAllocationSession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    * span integer attribute "bugsnag.system.memory.spaces.device.min" should be greater than 0
    * span integer attribute "bugsnag.system.memory.spaces.device.max" should be greater than 0
    * a span integer attribute "bugsnag.system.memory.spaces.device.min" is less than or equal to span integer attribute "bugsnag.system.memory.spaces.device.max"

Scenario: App session span does not parent other spans
    Given I load scenario "AppSessionResourceUsageScenario"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "session_type" to "parent check session"
    And I configure scenario "span_duration" to "2.0"
    And I configure scenario "create_child_span" to "true"
    And I configure scenario "work_duration" to "1.0"
    And I configure scenario "work_on_thread" to "main"
    And I configure scenario "variant_name" to "ParentCheck"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 2 spans
    Then a span field "name" equals "[AppSession/ParentCheckSession]"
    * a span string attribute "bugsnag.span.category" equals "app_session"
    And a span field "name" equals "ChildSpanInsideSession"
    * a span string attribute "bugsnag.span.category" equals "custom"
