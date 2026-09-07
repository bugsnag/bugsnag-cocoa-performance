Feature: Spans with collected Disk IOPS metrics

  # ============================================================================
  # QA doc scenario coverage index (ROAD 2233 - Disk IOPS Maze runner Scenarios)
  # Every doc scenario is accounted for below. Scenarios covered in THIS file
  # also carry a "# QA doc SCENARIO n" comment directly above the matching
  # Scenario: line.
  #
  # SCENARIO 1  "SDK emits all three disk IOPS attributes as IntValue on
  #             eligible spans" -> IN THIS FILE (3 scenarios: First class spans /
  #             Eligible span exports / App session spans)
  # SCENARIO 2  "Disk IOPS is computed correctly using platform-specific
  #             formula" -> UNIT TESTS: DiskIOMetricsTests
  #             (testKnownGoodDatasetFromScopingDoc + rounding/block-size cases).
  #             Note: the SDK uses the real statfs f_bsize (4 KB fallback), not
  #             a hardcoded 16 KB block. Android rows -> bugsnag-android repo.
  # SCENARIO 3  "Disk metrics are NOT emitted when span duration is invalid"
  #             -> UNIT TESTS: DiskIOMetricsTests (testZeroDurationReturnsInvalid,
  #             testNegativeDurationReturnsInvalid). Not reachable end-to-end:
  #             the collector times its own snapshots, and Maze rejects
  #             end < start payloads.
  # SCENARIO 4  "Negative counter deltas ... for all dimensions" -> IN THIS FILE
  #             ("Negative byte deltas cause disk IOPS attributes to be
  #             omitted") + UNIT TESTS (read/write/both regression). Per
  #             PLAT-17202 Option B the behaviour is OMISSION, superseding the
  #             doc's clamp-to-zero wording.
  # SCENARIO 5  "Disk metrics are omitted gracefully when counter source is
  #             unavailable" -> IN THIS FILE (start-snapshot-unavailable
  #             scenario) + UNIT TESTS: DiskIOCollectorTests fault-mode cases
  #             (fail-at-start / fail-at-end). /proc/self/io rows ->
  #             bugsnag-android repo.
  # SCENARIO 6  "zero and asymmetric activity" -> IN THIS FILE (read-only /
  #             write-only scenarios). Zero-activity exact-0 row -> UNIT TEST
  #             testZeroDeltaProducesZeroIOPS (process-shared counters make
  #             exact zeros unassertable on device).
  # SCENARIO 7  "Concurrent spans ... independent disk IOPS" -> IN THIS FILE.
  # SCENARIO 8  "Orphaned span snapshot does not cause memory leak" -> IN THIS
  #             FILE.
  # SCENARIO 9  "app lifecycle transitions" -> IN THIS FILE (2 scenarios;
  #             app-termination row omitted - no next-launch assertion
  #             mechanism in the fixture).
  # SCENARIO 10 "Spans from older SDK without disk IOPS ... stored correctly"
  #             -> BACKEND/PIPELINE SUITE SCOPE (not testable from this SDK).
  # SCENARIO 11 "valid Float64 under high and burst I/O" -> IN THIS FILE
  #             (SQLite / burst / file-copy scenarios). Values are intValue per
  #             the SDK, which makes NaN/Infinity unrepresentable.
  # SCENARIO 12 "OTLP payload contains exactly 3 disk attributes ..." -> IN
  #             THIS FILE (merged into the Eligible-span scenario; doubleValue
  #             in the doc corrected to intValue per the SDK source).
  # SCENARIO 13 "Existing system metrics are unaffected" -> IN THIS FILE
  #             (2 scenarios).
  # SCENARIO 14 "mixed SDK versions ... partial coverage" -> BACKEND/PIPELINE
  #             SUITE SCOPE (percentile aggregation is a dashboard concern).
  # SCENARIO 15 "SDK delivers span payload to trace API successfully" -> IN
  #             THIS FILE (merged into the Eligible-span scenario; receiving
  #             the span proves trace-API acceptance).
  #
  # Additions beyond the doc: M-1 disabled-flag, M-2 default state, M-4
  # ineligible span types (3 scenarios), M-5 very short span, plus the
  # EarlySpan lifecycle-exclusion scenario.
  # ============================================================================

  # Ground truth (from SDK source, BSGDiskIOCollector.mm / OtlpTraceEncoding.mm):
  # - Attribute keys: bugsnag.system.disk.iops_read / iops_write / iops_total
  # - Values are int64 and exported as OTLP intValue (integers are always
  #   finite: NaN/Infinity cannot be represented, so "finite" is proven by the
  #   integer-typed steps themselves).
  # - Gating: enabledMetrics.disk (default NO) AND span-level tri-state
  #   metricsOptions.disk (unset -> first-class spans only).
  # - There is no OS-version floor in the collection code: proc_pid_rusage and
  #   statfs are available on every iOS version this SDK supports, so these
  #   scenarios run identically across the whole BitBar device matrix
  #   (including the oldest iOS entry).
  #
  # Note on value assertions: disk byte counters are process-wide and
  # best-effort. A counter for which the workload guarantees traffic asserts
  # >= 1; the opposite counter asserts >= 0 (never == 0 - other threads and
  # system I/O share the process counters).
  #
  # Span eligibility (shouldSampleDiskIO): the gate does not branch on span
  # category, so any first-class span (custom, app_session, view-load) is
  # eligible by default. app_start spans are excluded in practice because they
  # begin before BugsnagPerformance.start(), when no start snapshot can exist -
  # the "EarlySpan" scenario below drives exactly that path.

  # QA doc: not in spec - added as M-2 (explicit default-configuration state)
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

  # QA doc: not in spec - added as M-1 (disk metrics DISABLED via configuration flag)
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

  # QA doc SCENARIO 1: "SDK emits all three disk IOPS attributes as IntValue on eligible spans"
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

  # QA doc: not in spec - added as M-4 (ineligible span types carry no disk attributes)
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

  # QA doc: not in spec - added as M-4 companion (per-span tri-state override widens eligibility)
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

  # QA doc: not in spec - added as M-4 companion (per-span tri-state override narrows eligibility)
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

  # E2E-1a - attribute presence and shape on a custom first-class span.
  # The three keys are present, integer-typed (intValue - the integer steps
  # only match intValue entries), internally consistent (total == read +
  # write), and no legacy/duplicate disk namespace appears anywhere in the
  # payload. Span steps read attributes from
  # resourceSpans.*.scopeSpans.*.spans.*.attributes, so the nesting is
  # validated implicitly by every assertion below.
  # QA doc SCENARIO 1: "SDK emits all three disk IOPS attributes as IntValue on eligible spans"
  # QA doc SCENARIO 12: "OTLP payload contains exactly 3 disk attributes with correct keys and structure"
  # QA doc SCENARIO 15: "SDK delivers span payload to trace API successfully with disk IOPS attributes"
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
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0
    * the span named "DiskIOPSScenarioHappyPath" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"
    * no span attribute key starts with "bugsnag.app.disk"
    * no span attribute key starts with "bugsnag.device.disk"

  # E2E-1b - the app_session span type (real startAppSessionSpan API) is
  # disk-eligible and carries the same well-formed attribute set.
  # QA doc SCENARIO 1: "SDK emits all three disk IOPS attributes as IntValue on eligible spans" (app_session span type row)
  Scenario: App session spans export disk IOPS attributes
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.0"
    And I configure scenario "span_type" to "app_session"
    And I configure scenario "workload" to "write"
    And I configure scenario "workload_bytes" to "1048576"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "[AppSession/DiskIOPS]"
    * every span bool attribute "bugsnag.span.first_class" is true
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0
    * the span named "[AppSession/DiskIOPS]" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"
    * no span attribute key starts with "bugsnag.app.disk"
    * no span attribute key starts with "bugsnag.device.disk"

  # E2E-3 - asymmetric activity. The workload-guaranteed counter must be
  # strictly positive (the fixture forces real disk traffic via F_NOCACHE +
  # fsync); the opposite counter only asserts >= 0 because the counters are
  # process-wide and shared with system I/O.
  # QA doc SCENARIO 6: "Disk IOPS attributes are emitted correctly for zero and asymmetric activity" (read-only row)
  Scenario: A read-only workload produces positive read IOPS
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.5"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "workload" to "read"
    And I configure scenario "workload_bytes" to "4194304"
    And I configure scenario "variant_name" to "ReadOnly"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIOPSScenarioReadOnly"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 1
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * the span named "DiskIOPSScenarioReadOnly" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # QA doc SCENARIO 6: "Disk IOPS attributes are emitted correctly for zero and asymmetric activity" (write-only row;
  # the zero-activity row is unit-covered by testZeroDeltaProducesZeroIOPS - exact zeros are unassertable on device)
  Scenario: A write-only workload produces positive write IOPS
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.5"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "workload" to "write"
    And I configure scenario "workload_bytes" to "4194304"
    And I configure scenario "variant_name" to "WriteOnly"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIOPSScenarioWriteOnly"
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 1
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * the span named "DiskIOPSScenarioWriteOnly" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # E2E-4 - concurrent spans (A: T0->T3, B nested: T1->T2). All forced I/O
  # happens outside B's window, so A's write counter is positive and must
  # differ from B's near-idle value - identical values would indicate a shared
  # or leaked snapshot.
  # QA doc SCENARIO 7: "Concurrent spans each compute independent disk IOPS without collision"
  Scenario: Concurrent overlapping spans each export their own disk IOPS attributes
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "concurrent" to "true"
    And I configure scenario "variant_name" to "Concurrent"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 2 spans
    Then a span field "name" equals "DiskIOPSScenarioConcurrentA"
    * a span field "name" equals "DiskIOPSScenarioConcurrentB"
    * a span named "DiskIOPSScenarioConcurrentA" started before a span named "DiskIOPSScenarioConcurrentB"
    * a span named "DiskIOPSScenarioConcurrentB" ended before a span named "DiskIOPSScenarioConcurrentA"
    * the span named "DiskIOPSScenarioConcurrentA" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 1
    * the span named "DiskIOPSScenarioConcurrentA" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "DiskIOPSScenarioConcurrentA" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"
    * the span named "DiskIOPSScenarioConcurrentB" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * the span named "DiskIOPSScenarioConcurrentB" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "DiskIOPSScenarioConcurrentB" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"
    * the span named "DiskIOPSScenarioConcurrentA" integer attribute "bugsnag.system.disk.iops_write" does not equal the span named "DiskIOPSScenarioConcurrentB" integer attribute "bugsnag.system.disk.iops_write"

  # E2E-5 - orphan smoke test. 50 spans start and never end while 100 spans
  # complete normally: every completed span must deliver a valid attribute set
  # and the app must not crash. The 50 orphans never reach the payload, hence
  # "exactly 100".
  # QA doc SCENARIO 8: "Orphaned span snapshot does not cause memory leak"
  Scenario: Orphaned spans do not corrupt disk IOPS collection for completed spans
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "orphan_mode" to "true"
    And I configure scenario "variant_name" to "OrphanSmoke"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 100 spans
    Then every span field "name" equals "DiskIOPSScenarioOrphanSmoke"
    * every span integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * every span integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * every span integer attribute "bugsnag.system.disk.iops_total" is greater than or equal to 0

  # E2E-6a - mid-span background -> foreground. App-session spans are the one
  # span type the SDK keeps open across backgrounding (all other open spans
  # are aborted by design - see abortOpenSpansOnBackground), so the app
  # session span is the honest vehicle for this row: it must survive the
  # round-trip and deliver a valid attribute set.
  # QA doc SCENARIO 9: "Disk IOPS is captured correctly across app lifecycle transitions" (mid-span background transition row)
  Scenario: A span held open across background and foreground delivers disk IOPS attributes
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "lifecycle_mode" to "mid_span_background"
    And I start bugsnag
    And I run the loaded scenario
    And I switch to the web browser for 2 seconds
    And I wait for exactly 1 span
    Then a span field "name" equals "[AppSession/DiskIOPS]"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * the span named "[AppSession/DiskIOPS]" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # E2E-6b - span started while the app is in the background, ended after the
  # app returns to the foreground: delivered with a valid attribute set.
  # QA doc SCENARIO 9: "Disk IOPS is captured correctly across app lifecycle transitions" (span starts in background row;
  # the app-termination row is omitted - the fixture has no next-launch span-delivery assertion mechanism)
  Scenario: A span started in the background delivers disk IOPS attributes
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "lifecycle_mode" to "start_in_background"
    And I configure scenario "variant_name" to "StartedInBackground"
    And I start bugsnag
    And I run the loaded scenario
    And I switch to the web browser for 2 seconds
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIOPSScenarioStartedInBackground"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * the span named "DiskIOPSScenarioStartedInBackground" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # E2E-7a - intensive SQLite workload (1000 single-statement transactions,
  # each forcing a journal write). Values are intValue-typed integers, so
  # NaN/Infinity are unrepresentable; the assertions prove they are present,
  # positive where guaranteed, and internally consistent.
  # QA doc SCENARIO 11: "Disk IOPS values are valid Float64 under high and burst I/O conditions"
  # (intensive SQLite 1000+ queries row; values are intValue per the SDK, not Float64 - see feature header)
  Scenario: An intensive SQLite workload produces valid disk IOPS values
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "workload" to "sqlite"
    And I configure scenario "variant_name" to "SQLite"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIOPSScenarioSQLite"
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 1
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * the span named "DiskIOPSScenarioSQLite" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # E2E-7b - 10MB burst then ~10s idle. IOPS must be averaged over the FULL
  # span duration: 10MB / 4KB blocks = 2560 ops, so a correct implementation
  # reports well under 600 ops/s for a 10 second span, while averaging over
  # the burst window alone would report several thousand. The upper bound
  # holds for any realistic filesystem block size (>= 4KB).
  # QA doc SCENARIO 11: "Disk IOPS values are valid Float64 under high and burst I/O conditions" (10MB burst write then idle row)
  Scenario: Burst write IOPS are averaged over the full span duration
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "10.0"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "workload" to "burst_write"
    And I configure scenario "workload_bytes" to "10485760"
    And I configure scenario "variant_name" to "BurstWrite"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIOPSScenarioBurstWrite"
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 1
    * span integer attribute "bugsnag.system.disk.iops_write" should be less than 600
    * the span named "DiskIOPSScenarioBurstWrite" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # E2E-7c - 50MB file copy: both counters must be positive.
  # QA doc SCENARIO 11: "Disk IOPS values are valid Float64 under high and burst I/O conditions" (50MB file copy row)
  Scenario: A large file copy produces positive read and write IOPS
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "workload" to "file_copy"
    And I configure scenario "workload_bytes" to "52428800"
    And I configure scenario "variant_name" to "FileCopy"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIOPSScenarioFileCopy"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 1
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 1
    * the span named "DiskIOPSScenarioFileCopy" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # M-5 - very short span (well under 100ms of wall clock around real forced
  # I/O): the tiny-denominator path must still produce integer (finite),
  # non-negative, internally consistent values.
  # QA doc: not in spec - added as M-5 (very short span / tiny-denominator guard)
  Scenario: A very short span with real disk activity produces valid disk IOPS values
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.05"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "workload" to "write"
    And I configure scenario "workload_bytes" to "262144"
    And I configure scenario "variant_name" to "ShortSpan"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIOPSScenarioShortSpan"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0
    * the span named "DiskIOPSScenarioShortSpan" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # Lifecycle exclusion - a span opened before BugsnagPerformance.start() has
  # no start snapshot, so it must export cleanly with no disk attributes.
  # (This is also why app_start spans never carry disk attributes.)
  # QA doc SCENARIO 5: "Disk metrics are omitted gracefully when counter source is unavailable"
  # (the only device-reachable variant: no start snapshot exists. The proc_pid_rusage failure
  # rows are unit-covered via the collector fault-mode tests - not injectable on a real device)
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

  # QA doc SCENARIO 4: "Negative counter deltas are clamped to zero for all dimensions"
  # (superseded by PLAT-17202 Option B: a regressed counter now OMITS the whole
  # attribute set - never clamped, never per-dimension - consistent with the
  # invalid-snapshot and non-positive-duration paths. The span itself must
  # still be delivered intact. Driven via the test-only fault hook retained
  # under PLAT-17203 Option A.)
  Scenario: Negative byte deltas cause disk IOPS attributes to be omitted
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
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span attribute "bugsnag.system.disk.iops_read" does not exist
    * every span attribute "bugsnag.system.disk.iops_write" does not exist
    * every span attribute "bugsnag.system.disk.iops_total" does not exist

  # E2E-8 - disk metrics coexist with the pre-existing resource metrics.
  # (Rendering/frozen-frame attributes are deliberately not asserted here:
  # they require a driven UI animation and are covered by metrics_frame.feature;
  # combining them with this scenario would be flaky, not more thorough.)
  # QA doc SCENARIO 13: "Existing system metrics are unaffected by disk IOPS collection" (enabled with valid disk data row)
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
    * the span named "DiskIOPSScenarioAllMetrics" array attribute "bugsnag.system.cpu_measures_total" is not empty
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * the span named "DiskIOPSScenarioAllMetrics" array attribute "bugsnag.system.cpu_measures_main_thread" is not empty
    * the span named "DiskIOPSScenarioAllMetrics" array attribute "bugsnag.system.memory.timestamps" is not empty
    * span integer attribute "bugsnag.system.memory.spaces.device.size" should be greater than 0
    * the span named "DiskIOPSScenarioAllMetrics" array attribute "bugsnag.system.memory.spaces.device.used" is not empty
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0

  # E2E-8 (zero-disk-activity state) - the non-disk code path is unaffected
  # when disk is off.
  # QA doc SCENARIO 13: "Existing system metrics are unaffected by disk IOPS collection" (disabled / zero disk state rows)
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
