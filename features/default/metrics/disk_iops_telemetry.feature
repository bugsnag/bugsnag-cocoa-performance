Feature: Spans with collected Disk IOPS metrics

  # Note on value assertions:
  # Disk byte counters are process-wide and best-effort. Some CI hosts /
  # simulators legitimately report a zero delta over a short span, so the
  # happy-path scenarios assert key presence, integer (OTEL intValue) typing
  # and non-negativity rather than a strictly positive value.

  Scenario: With default settings, disk IOPS metrics are disabled
    Given I load scenario "DiskIOPSScenario"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.2"
    And I configure scenario "disk_work_bytes" to "0"
    And I configure scenario "variant_name" to "DefaultSettingsDiskDisabled"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * a span field "name" equals "DiskIOPSScenarioDefaultSettingsDiskDisabled"
    * every span field "kind" equals 1
    * every span attribute "bugsnag.system.disk.iops_read" does not exist
    * every span attribute "bugsnag.system.disk.iops_write" does not exist
    * every span attribute "bugsnag.system.disk.iops_total" does not exist

  Scenario: When disk metrics are disabled, no attributes are produced no matter what
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "false"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.2"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_metrics_disk" to "yes"
    And I configure scenario "variant_name" to "NoMetrics"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "DiskIOPSScenarioNoMetrics"
    * every span attribute "bugsnag.system.disk.iops_read" does not exist
    * every span attribute "bugsnag.system.disk.iops_write" does not exist
    * every span attribute "bugsnag.system.disk.iops_total" does not exist

  Scenario: First class spans produce disk IOPS attributes
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.2"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "variant_name" to "FirstClass"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "DiskIOPSScenarioFirstClass"
    * every span bool attribute "bugsnag.span.first_class" is true
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0

  Scenario: Non-first-class spans do not produce disk IOPS attributes by default
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.2"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "no"
    And I configure scenario "variant_name" to "NonFirstClass"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "DiskIOPSScenarioNonFirstClass"
    * every span bool attribute "bugsnag.span.first_class" is false
    * every span attribute "bugsnag.system.disk.iops_read" does not exist
    * every span attribute "bugsnag.system.disk.iops_write" does not exist
    * every span attribute "bugsnag.system.disk.iops_total" does not exist

  Scenario: When metrics.disk = yes, non-first-class spans still produce disk IOPS attributes
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.2"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "no"
    And I configure scenario "opts_metrics_disk" to "yes"
    And I configure scenario "variant_name" to "NonFirstClassWithMetrics"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "DiskIOPSScenarioNonFirstClassWithMetrics"
    * every span bool attribute "bugsnag.span.first_class" is false
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0

  Scenario: When metrics.disk = no, first-class spans do not produce disk IOPS attributes
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.2"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "opts_metrics_disk" to "no"
    And I configure scenario "variant_name" to "FirstClassWithMetricsOff"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "DiskIOPSScenarioFirstClassWithMetricsOff"
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span attribute "bugsnag.system.disk.iops_read" does not exist
    * every span attribute "bugsnag.system.disk.iops_write" does not exist
    * every span attribute "bugsnag.system.disk.iops_total" does not exist

  # PLAT-16902 - happy path across the full span lifecycle.
  # A start snapshot, an end snapshot and a successful computation are all
  # required for these three keys to appear on the exported span, so their
  # presence on the completed span proves the whole lifecycle ran.
  Scenario: Eligible span exports a complete, well-formed disk IOPS attribute set
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.0"
    And I configure scenario "disk_work_bytes" to "1048576"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "variant_name" to "HappyPath"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then the trace "Content-Type" header equals "application/json"
    * a span field "name" equals "DiskIOPSScenarioHappyPath"
    * every span field "kind" equals 1
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * every span bool attribute "bugsnag.span.first_class" is true
    # All three keys present, integer-typed (intValue) and non-negative.
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0
    # total is emitted alongside, and consistent with, read + write.
    * the span named "DiskIOPSScenarioHappyPath" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # PLAT-16903 - start snapshot unavailable.
  # The span is opened before BugsnagPerformance.start(), so disk sampling is
  # gated off and no start snapshot is stored. It is ended after start, when
  # sampling is active, driving the real "no start snapshot" omission path.
  Scenario: Span exports cleanly with no disk attributes when the start snapshot is unavailable
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.5"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "start_before_bugsnag_start" to "true"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "DiskIOPSScenarioEarlySpan"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * the span named "DiskIOPSScenarioEarlySpan" attribute "bugsnag.system.disk.iops_read" does not exist
    * the span named "DiskIOPSScenarioEarlySpan" attribute "bugsnag.system.disk.iops_write" does not exist
    * the span named "DiskIOPSScenarioEarlySpan" attribute "bugsnag.system.disk.iops_total" does not exist

  # PLAT-16903 - start snapshot capture fails at the platform level.
  Scenario: Span exports cleanly when start snapshot capture fails
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.5"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "disk_fault_mode" to "fail_start"
    And I configure scenario "variant_name" to "StartSnapshotFailed"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIOPSScenarioStartSnapshotFailed"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span attribute "bugsnag.system.disk.iops_read" does not exist
    * every span attribute "bugsnag.system.disk.iops_write" does not exist
    * every span attribute "bugsnag.system.disk.iops_total" does not exist

  # PLAT-16904 - end snapshot unavailable. The start snapshot is captured and
  # then consumed (and therefore cleaned up) before the end read is rejected.
  Scenario: Span exports cleanly when end snapshot capture fails
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.5"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "disk_fault_mode" to "fail_end"
    And I configure scenario "variant_name" to "EndSnapshotFailed"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIOPSScenarioEndSnapshotFailed"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span attribute "bugsnag.system.disk.iops_read" does not exist
    * every span attribute "bugsnag.system.disk.iops_write" does not exist
    * every span attribute "bugsnag.system.disk.iops_total" does not exist

  # PLAT-16905 - invalid duration (end timestamp == start timestamp).
  Scenario: Span exports cleanly with no disk attributes when the computed duration is not positive
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.5"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "disk_fault_mode" to "zero_duration"
    And I configure scenario "variant_name" to "ZeroDuration"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIOPSScenarioZeroDuration"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span attribute "bugsnag.system.disk.iops_read" does not exist
    * every span attribute "bugsnag.system.disk.iops_write" does not exist
    * every span attribute "bugsnag.system.disk.iops_total" does not exist

  # PLAT-16905 - counter regression / negative delta.
  # By design this is clamped to zero rather than omitted, so the span must
  # still export a valid, non-negative (zero) attribute set - never a negative
  # or otherwise malformed value.
  Scenario: Negative byte deltas are clamped to zero rather than exported as invalid values
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.5"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "disk_fault_mode" to "negative_delta"
    And I configure scenario "variant_name" to "NegativeDelta"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIOPSScenarioNegativeDelta"
    * every span integer attribute "bugsnag.system.disk.iops_read" equals 0
    * every span integer attribute "bugsnag.system.disk.iops_write" equals 0
    * every span integer attribute "bugsnag.system.disk.iops_total" equals 0

  # PLAT-16907 - overlapping spans keep independent snapshot state.
  # Neither span is the other's parent, so a leaked/shared snapshot would show
  # up as a missing or internally inconsistent attribute set on one of them.
  Scenario: Concurrent overlapping spans each export their own disk IOPS attributes
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.5"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "concurrent" to "true"
    And I configure scenario "variant_name" to "Concurrent"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 2 spans
    Then a span field "name" equals "DiskIOPSScenarioConcurrentA"
    * a span field "name" equals "DiskIOPSScenarioConcurrentB"
    * a span named "DiskIOPSScenarioConcurrentA" started before a span named "DiskIOPSScenarioConcurrentB"
    * a span named "DiskIOPSScenarioConcurrentA" ended before a span named "DiskIOPSScenarioConcurrentB"
    # Each span carries its own complete, self-consistent attribute set.
    * the span named "DiskIOPSScenarioConcurrentA" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "DiskIOPSScenarioConcurrentA" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * the span named "DiskIOPSScenarioConcurrentA" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"
    * the span named "DiskIOPSScenarioConcurrentB" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "DiskIOPSScenarioConcurrentB" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * the span named "DiskIOPSScenarioConcurrentB" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # PLAT-16906 - disk metrics coexist with the pre-existing resource metrics.
  Scenario: Disk metrics do not displace existing CPU and memory metrics
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "variant_name" to "AllMetrics"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "DiskIOPSScenarioAllMetrics"
    * every span bool attribute "bugsnag.span.first_class" is true
    # Existing CPU payload shape is preserved. The exact sample count is timing
    # dependent (and covered by metrics_cpu.feature); what matters here is that
    # adding disk metrics does not drop or empty the existing attributes.
    * the span named "DiskIOPSScenarioAllMetrics" array attribute "bugsnag.system.cpu_measures_total" is not empty
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * the span named "DiskIOPSScenarioAllMetrics" array attribute "bugsnag.system.cpu_measures_main_thread" is not empty
    # Existing memory payload shape is preserved.
    * the span named "DiskIOPSScenarioAllMetrics" array attribute "bugsnag.system.memory.timestamps" is not empty
    * span integer attribute "bugsnag.system.memory.spaces.device.size" should be greater than 0
    * the span named "DiskIOPSScenarioAllMetrics" array attribute "bugsnag.system.memory.spaces.device.used" is not empty
    # And disk metrics are added alongside them.
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0

  # PLAT-16906 - the non-disk code path is unaffected when disk is off.
  Scenario: Existing CPU and memory metrics are unchanged for spans without disk metrics
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "false"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "variant_name" to "NoDiskMetricsRegression"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "DiskIOPSScenarioNoDiskMetricsRegression"
    * every span bool attribute "bugsnag.span.first_class" is true
    * the span named "DiskIOPSScenarioNoDiskMetricsRegression" array attribute "bugsnag.system.cpu_measures_total" is not empty
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * the span named "DiskIOPSScenarioNoDiskMetricsRegression" array attribute "bugsnag.system.memory.timestamps" is not empty
    * span integer attribute "bugsnag.system.memory.spaces.device.size" should be greater than 0
    * every span attribute "bugsnag.system.disk.iops_read" does not exist
    * every span attribute "bugsnag.system.disk.iops_write" does not exist
    * every span attribute "bugsnag.system.disk.iops_total" does not exist
