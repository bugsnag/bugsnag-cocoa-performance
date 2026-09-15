Feature: Disk IOPS

  # iOS ground truth (BSGDiskIOCollector.mm / OtlpTraceEncoding.mm):
  # - Attribute keys: bugsnag.system.disk.iops_read / iops_write / iops_total
  #   this file asserts the keys the iOS SDK actually emits. ***
  # - Values are int64 exported as OTLP intValue (NaN/Infinity unrepresentable).
  # - Gating: enabledMetrics.disk (default NO) AND span-level tri-state
  #   metricsOptions.disk (unset -> first-class spans only).
  # - No OS-version floor: proc_pid_rusage and statfs exist on every supported
  #   iOS version, so this file runs across the whole BitBar device matrix.
  # - Counters are process-wide: a counter the workload guarantees asserts
  #   >= 1 (forced F_NOCACHE + fsync I/O); the opposite counter asserts >= 0.

  # ==========================================================================
  # ROAD 2233 - Scenario 1
  # SDK emits all 3 disk IOPS attributes as IntValue on eligible spans.
  #
  # Covered by unit tests:
  #   DiskIOCollectorTests (testStartFollowedByEndReturnsThreeIOPSAttributes)
  #   DiskIOLifecycleGatingTests (testDiskCollectionWhenEnabledAndStarted)
  # ==========================================================================
  Scenario Outline: SDK emits all 3 disk IOPS attributes as IntValue on eligible spans
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.0"
    And I configure scenario "span_type" to "<span_type>"
    And I configure scenario "span_name" to "<span_name>"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "workload" to "write"
    And I configure scenario "workload_bytes" to "1048576"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "<span_name>"
    * every span bool attribute "bugsnag.span.first_class" is true
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_total" is greater than or equal to 0
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

    Examples:
      | platform | span_type   | span_name             |
      | ios      | custom      | DiskIopsCustom        |
      | ios      | app_session | [AppSession/DiskIops] |

  # iOS app_start spans begin BEFORE
  # BugsnagPerformance.start() (pre-main), when no start snapshot can exist,
  # so on iOS they never carry disk attributes by design. The exclusion path
  # itself is proven end-to-end by the Scenario 5 "EarlySpan" scenario below.

  # ==========================================================================
  # ROAD 2233 - Scenario 2
  # Maze cannot freeze proc_pid_rusage counters or the clock, so it cannot
  # assert the ROAD table numbers. It runs the real collector path and checks
  # the values the SDK actually computed on the device: integers >= 0 and
  # total = read + write. (Android additionally asserts internal
  # bugsnag.internal.disk_io.* debug attributes; the iOS SDK does not emit
  # internal debug attributes, so those steps have no iOS equivalent.)
  #
  # Covered by unit tests with injectable snapshots:
  #   DiskIOMetricsTests
  #     (testKnownGoodDatasetFromScopingDoc, testRoundingUsesLlround,
  #      testSubBlockDeltaRoundsToZero,
  #      testCapturedSnapshotUsesRealFilesystemBlockSize)
  # Note: the doc's 16KB block assumption is stale for iOS - the SDK divides
  # by the real statfs f_bsize (4KB fallback).
  # ==========================================================================
  Scenario Outline: SDK reports real disk IOPS values computed on the device
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.0"
    And I configure scenario "span_type" to "<span_type>"
    And I configure scenario "span_name" to "<span_name>"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "workload" to "write"
    And I configure scenario "workload_bytes" to "2097152"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "<span_name>"
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 1
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_total" is greater than or equal to 1
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

    Examples:
      | platform | span_type   | span_name             |
      | ios      | custom      | DiskIopsCustom        |
      | ios      | app_session | [AppSession/DiskIops] |

  # ==========================================================================
  # ROAD 2233 - Scenario 3
  # Maze cannot rewind the device clock, and the collector times its own
  # snapshots (span start/end timestamps are not its timebase), so the
  # zero-duration path is driven by the test-only fault hook (kept under
  # PLAT-17203 Option A). The real collector still runs: the span is
  # delivered and all iops_* attributes are omitted. The negative-duration
  # row cannot run e2e at all (Maze's TraceValidator rejects end < start
  # payloads) and stays unit-only.
  #
  # Covered by unit tests:
  #   DiskIOMetricsTests (testZeroDurationReturnsInvalid,
  #                       testNegativeDurationReturnsInvalid)
  #   DiskIOCollectorTests (testZeroDurationFaultOmitsAttributes)
  # ==========================================================================
  Scenario Outline: SDK omits disk IOPS when span duration is invalid
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.5"
    And I configure scenario "span_type" to "<span_type>"
    And I configure scenario "span_name" to "<span_name>"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "workload" to "write"
    And I configure scenario "workload_bytes" to "524288"
    And I configure scenario "disk_fault_mode" to "zero_duration"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "<span_name>"
    * every span field "kind" equals 1
    * the span named "<span_name>" attribute "bugsnag.system.disk.iops_read" does not exist
    * the span named "<span_name>" attribute "bugsnag.system.disk.iops_write" does not exist
    * the span named "<span_name>" attribute "bugsnag.system.disk.iops_total" does not exist

    Examples:
      | platform | span_type   | duration_fault | span_name             |
      | ios      | custom      | zero           | DiskIopsCustom        |
      | ios      | app_session | zero           | [AppSession/DiskIops] |

  # ==========================================================================
  # ROAD 2233 - Scenario 4
  # Doc says "negative counter deltas are clamped to zero"; per the recorded
  # a regressed counter omits ALL disk iops_* attributes - the other ED-allowed
  # path - and still guarantees no negative values are emitted.
  #
  # Why Maze cannot cover the doc's exact vectors:
  # - Requires injecting regressing counters (end < start); proc_pid_rusage
  #   counters are monotonic on a real device.
  #
  # Covered by unit tests with injectable snapshots:
  #   DiskIOMetricsTests (testNegativeReadDeltaOmitsAttributes,
  #                       testNegativeWriteDeltaOmitsAttributes,
  #                       testBothCountersRegressOmitsAttributes)
  #   DiskIOCollectorTests (testNegativeDeltaFaultOmitsAttributes)
  #
  # The scenario below drives the regression path end-to-end via the fault
  # hook: no negatives emitted (whole set omitted); span still delivered.
  # ==========================================================================
  Scenario: Negative byte deltas cause disk IOPS attributes to be omitted
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.5"
    And I configure scenario "span_name" to "DiskIopsNegativeDelta"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "disk_fault_mode" to "negative_delta"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIopsNegativeDelta"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span attribute "bugsnag.system.disk.iops_read" does not exist
    * every span attribute "bugsnag.system.disk.iops_write" does not exist
    * every span attribute "bugsnag.system.disk.iops_total" does not exist

  # ==========================================================================
  # ROAD 2233 - Scenario 5
  # Disk metrics are omitted gracefully when the counter source is
  # unavailable. iOS source is proc_pid_rusage; the doc's failure wordings
  # ("returns non-zero error" / "result unavailable" / "corrupted struct")
  # cannot be induced in the real kernel from a fixture, so the FaultSpan
  # outline drives the two injection points of the test-only fault hook, and
  # the EarlySpan scenario drives the real (no-injection) omission path.
  #
  # Covered by unit tests:
  #   DiskIOCollectorTests
  #     (testFailAtStartFaultStoresNoStartSnapshotAndOmitsAttributes,
  #      testFailAtEndFaultOmitsAttributesAndStillCleansUp,
  #      testEndWithoutMatchingStartReturnsNil)
  # ==========================================================================
  Scenario Outline: Disk metrics are omitted gracefully when counter source is unavailable
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "span_name" to "FaultSpan"
    And I configure scenario "workload" to "write"
    And I configure scenario "workload_bytes" to "524288"
    And I configure scenario "disk_fault_mode" to "<fault_mode>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "FaultSpan"
    * every span field "kind" equals 1
    # CPU and memory metrics remain intact.
    * the span named "FaultSpan" array attribute "bugsnag.system.cpu_measures_total" is not empty
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * the span named "FaultSpan" array attribute "bugsnag.system.memory.timestamps" is not empty
    # Disk attributes are omitted, whole-set.
    * the span named "FaultSpan" attribute "bugsnag.system.disk.iops_read" does not exist
    * the span named "FaultSpan" attribute "bugsnag.system.disk.iops_write" does not exist
    * the span named "FaultSpan" attribute "bugsnag.system.disk.iops_total" does not exist

    Examples:
      | platform | failure_mode                              | fault_mode |
      | ios      | snapshot read fails at span start (rusage error) | fail_start |
      | ios      | snapshot read fails at span end (rusage error)   | fail_end   |

  # ROAD 2233 - Scenario 5 (real, no-injection variant): a span opened before
  # BugsnagPerformance.start() has no start snapshot, so it must export
  # cleanly with no disk attributes. This is also why iOS app_start spans
  # never carry disk attributes (see Scenario 1 note).
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
    Then a span field "name" equals "DiskIopsEarlySpan"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * the span named "DiskIopsEarlySpan" attribute "bugsnag.system.disk.iops_read" does not exist
    * the span named "DiskIopsEarlySpan" attribute "bugsnag.system.disk.iops_write" does not exist
    * the span named "DiskIopsEarlySpan" attribute "bugsnag.system.disk.iops_total" does not exist

  # ==========================================================================
  # ROAD 2233 - Scenario 6
  # Zero and asymmetric disk activity. 
  # iOS can force real disk traffic through the page cache (F_NOCACHE + fsync),
  # so the asymmetric rows run e2e. Deviation from the doc's exact-zero
  # cells: proc_pid_rusage counters are process-wide (system/SDK I/O shares
  # them), so exact 0 would be flaky on device - those cells assert >= 0 and
  # exact-zero semantics stay unit-covered.
  #
  # Covered by unit tests with injectable snapshots:
  #   DiskIOMetricsTests (testZeroDeltaProducesZeroIOPS)
  # ==========================================================================
  Scenario Outline: Disk IOPS attributes are emitted correctly for zero and asymmetric activity
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.5"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "span_name" to "DiskIopsActivity"
    And I configure scenario "workload" to "<workload>"
    And I configure scenario "workload_bytes" to "4194304"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIopsActivity"
    * the span named "DiskIopsActivity" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to <read_min>
    * the span named "DiskIopsActivity" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to <write_min>
    * the span named "DiskIopsActivity" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

    Examples:
      | platform | activity_type | workload | read_min | write_min |
      | ios      | none (idle)   | none     | 0        | 0         |
      | ios      | read-only     | read     | 1        | 0         |
      | ios      | write-only    | write    | 0        | 1         |

  # ==========================================================================
  # ROAD 2233 - Scenario 7
  # Concurrent spans compute independent disk IOPS without collision.
  # iOS runs this e2e: B is nested inside A
  # (A: T0->T3, B: T1->T2) and all forced I/O happens outside B's window, so
  # identical write values would indicate a shared or leaked snapshot.
  #
  # Covered by unit tests:
  #   DiskIOCollectorTests (testTwoSpansAreTrackedIndependently,
  #                         testConcurrentStartAndEndAreThreadSafe)
  # ==========================================================================
  Scenario: Concurrent spans each compute independent disk IOPS without collision
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "span_name" to "DiskIopsConcurrent"
    And I configure scenario "concurrent" to "true"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 2 spans
    Then a span field "name" equals "DiskIopsConcurrentA"
    * a span field "name" equals "DiskIopsConcurrentB"
    * a span named "DiskIopsConcurrentA" started before a span named "DiskIopsConcurrentB"
    * a span named "DiskIopsConcurrentB" ended before a span named "DiskIopsConcurrentA"
    * the span named "DiskIopsConcurrentA" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 1
    * the span named "DiskIopsConcurrentA" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "DiskIopsConcurrentA" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"
    * the span named "DiskIopsConcurrentB" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * the span named "DiskIopsConcurrentB" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "DiskIopsConcurrentB" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"
    * the span named "DiskIopsConcurrentA" integer attribute "bugsnag.system.disk.iops_write" does not equal the span named "DiskIopsConcurrentB" integer attribute "bugsnag.system.disk.iops_write"

  # ==========================================================================
  # ROAD 2233 - Scenario 8
  # Orphaned span snapshots do not corrupt completed spans or crash the app.
  # iOS runs this e2e: 50 spans start and never
  # end while 100 complete normally in a single batch; the 50 orphans never
  # reach the payload, hence "exactly 100".
  #
  # Covered by unit tests:
  #   DiskIOCollectorTests (testAbandonReleasesPendingStart,
  #                         testEndWithoutMatchingStartReturnsNil)
  # ==========================================================================
  Scenario: Orphaned span snapshot does not cause memory leak or corrupt completed spans
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "span_name" to "DiskIopsOrphanSmoke"
    And I configure scenario "orphan_mode" to "true"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 100 spans
    Then every span field "name" equals "DiskIopsOrphanSmoke"
    * every span integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * every span integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * every span integer attribute "bugsnag.system.disk.iops_total" is greater than or equal to 0

  # ==========================================================================
  # ROAD 2233 - Scenario 9
  # Disk IOPS across app lifecycle transitions. iOS DEVIATIONS from the
  # Android rows, all forced by SDK design (abortOpenSpansOnBackground aborts
  # every open non-app-session span when the app backgrounds):
  #  - mid-span transition must use an app-session span (the only survivor);
  #  - "ends while in background" requires the span to also START in the
  #    background (a span merely open at the transition is aborted);
  #  - the app-termination row is omitted (no next-launch assertion harness).
  #
  # Covered by unit tests:
  #   DiskIOLifecycleGatingTests (testDiskCollectionWhenEnabledAndStarted,
  #                               testNoDiskCollectionWhenNeverStarted)
  # ==========================================================================
  # Row: foreground -> background then foreground (mid-span transition).
  Scenario: SDK captures disk IOPS across a mid-span background transition
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "lifecycle_mode" to "mid_span_background"
    And I start bugsnag
    And I run the loaded scenario
    And I switch to the web browser for 2 seconds
    And I wait for exactly 1 span
    Then a span field "name" equals "[AppSession/DiskIops]"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * the span named "[AppSession/DiskIops]" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # Row: span starts and ends while in the background.
  Scenario: SDK captures disk IOPS for a span that ends while in the background
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "lifecycle_mode" to "start_end_in_background"
    And I configure scenario "span_name" to "DiskIopsCustom"
    And I start bugsnag
    And I run the loaded scenario
    And I switch to the web browser for 3 seconds
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIopsCustom"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * the span named "DiskIopsCustom" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # Row: background -> foreground (span starts in background, ends in foreground).
  Scenario: SDK captures disk IOPS for a span that starts in the background
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "lifecycle_mode" to "start_in_background"
    And I configure scenario "span_name" to "DiskIopsCustom"
    And I start bugsnag
    And I run the loaded scenario
    And I switch to the web browser for 2 seconds
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIopsCustom"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * the span named "DiskIopsCustom" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # ==========================================================================
  # ROAD 2233 - Scenario 10
  # Pipeline (-1 default) and API (null) behaviour are backend concerns.
  # iOS SDK scope: enabledMetrics.disk = false omits iops_* even when the
  # span-level metrics option asks for disk.
  #
  # Covered by unit tests:
  #   DiskIOLifecycleGatingTests (testNoDiskCollectionWhenDiskMetricsDisabled)
  # ==========================================================================
  Scenario: SDK omits disk IOPS when disk metrics are disabled
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "false"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.2"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_metrics_disk" to "yes"
    And I configure scenario "span_name" to "DiskIopsDisabled"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "DiskIopsDisabled"
    * the span named "DiskIopsDisabled" attribute "bugsnag.system.disk.iops_read" does not exist
    * the span named "DiskIopsDisabled" attribute "bugsnag.system.disk.iops_write" does not exist
    * the span named "DiskIopsDisabled" attribute "bugsnag.system.disk.iops_total" does not exist

  # ==========================================================================
  # ROAD 2233 - Scenario 11
  # Real SQLite / file workloads cannot yield the ROAD table numbers on a
  # device. Maze runs those workloads against the real collector and checks
  # valid integers (intValue typing makes NaN/Infinity unrepresentable).
  #
  # Covered by unit tests:
  #   DiskIOMetricsTests (testShortSubSecondSpanStillComputesNormally,
  #                       testRoundingUsesLlround)
  # ==========================================================================
  Scenario Outline: SDK reports valid disk IOPS under high and burst I/O
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "<duration_sec>"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "span_name" to "DiskIopsWorkload"
    And I configure scenario "workload" to "<workload>"
    And I configure scenario "workload_bytes" to "<workload_bytes>"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIopsWorkload"
    * the span named "DiskIopsWorkload" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to <read_min>
    * the span named "DiskIopsWorkload" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to <write_min>
    * the span named "DiskIopsWorkload" integer attribute "bugsnag.system.disk.iops_total" is greater than or equal to 1
    * the span named "DiskIopsWorkload" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

    Examples:
      | platform | workload    | duration_sec | workload_bytes | read_min | write_min |
      | ios      | sqlite      | 2.0          | 0              | 0        | 1         |
      | ios      | burst_write | 10.0         | 10485760       | 0        | 1         |
      | ios      | file_copy   | 5.0          | 52428800       | 1        | 1         |

  # ROAD 2233 - Scenario 11 (burst averaging): IOPS must be averaged over the
  # FULL span duration: 10MB / 4KB blocks = 2560 ops, so a correct
  # implementation reports well under 600 ops/s for a 10 second span, while
  # averaging over the burst window alone would report several thousand. The
  # bound holds for any realistic filesystem block size.
  Scenario: Burst write IOPS are averaged over the full span duration
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "10.0"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "span_name" to "DiskIopsWorkload"
    And I configure scenario "workload" to "burst_write"
    And I configure scenario "workload_bytes" to "10485760"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIopsWorkload"
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 1
    * span integer attribute "bugsnag.system.disk.iops_write" should be less than 600
    * the span named "DiskIopsWorkload" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # ==========================================================================
  # ROAD 2233 - Scenario 12
  # OTLP payload structure: the three iops_* keys with intValue encoding
  # (the integer steps only match intValue entries) and no legacy or raw
  #
  # Covered by unit tests:
  #   DiskIOCollectorTests (testStartFollowedByEndReturnsThreeIOPSAttributes,
  #                         testTotalEqualsReadPlusWrite)
  # ==========================================================================
  Scenario: OTLP payload contains exactly 3 disk IOPS attributes with intValue encoding
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.0"
    And I configure scenario "disk_work_bytes" to "1048576"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "span_name" to "DiskIopsCustom"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then the trace "Content-Type" header equals "application/json"
    * a span field "name" equals "DiskIopsCustom"
    * every span field "kind" equals 1
    * the trace payload field "resourceSpans.0.resource" string attribute "service.name" matches the regex "com.bugsnag.fixtures.cocoaperformance(xcframework)?"
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
    * every span bool attribute "bugsnag.span.first_class" is true
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0
    * the span named "DiskIopsCustom" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"
    * no span attribute key starts with "bugsnag.app.disk"
    * no span attribute key starts with "bugsnag.device.disk"

  # ==========================================================================
  # ROAD 2233 - Scenario 13
  # Disk IOPS does not affect existing system metrics. Frozen-frame attrs
  # require driven view frames and stay covered by metrics_frame.feature;
  # Maze checks CPU + memory on a first-class span with disk enabled and
  # disabled, mirroring the Android pair.
  #
  # Covered by unit tests:
  #   DiskIOLifecycleGatingTests (testNoDiskCollectionWhenDiskMetricsDisabled,
  #                               testDiskCollectionWhenEnabledAndStarted)
  # ==========================================================================
  Scenario: Existing system metrics are present when disk IOPS is enabled
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "span_name" to "DiskIopsIsolation"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "DiskIopsIsolation"
    * every span bool attribute "bugsnag.span.first_class" is true
    * the span named "DiskIopsIsolation" array attribute "bugsnag.system.cpu_measures_total" is not empty
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * the span named "DiskIopsIsolation" array attribute "bugsnag.system.cpu_measures_main_thread" is not empty
    * the span named "DiskIopsIsolation" array attribute "bugsnag.system.memory.timestamps" is not empty
    * span integer attribute "bugsnag.system.memory.spaces.device.size" should be greater than 0
    * the span named "DiskIopsIsolation" array attribute "bugsnag.system.memory.spaces.device.used" is not empty
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0

  Scenario: Existing system metrics are present when disk IOPS is disabled
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "false"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure bugsnag "memoryMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.5"
    And I configure scenario "disk_work_bytes" to "524288"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "span_name" to "DiskIopsIsolation"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then a span field "name" equals "DiskIopsIsolation"
    * every span bool attribute "bugsnag.span.first_class" is true
    * the span named "DiskIopsIsolation" array attribute "bugsnag.system.cpu_measures_total" is not empty
    * a span float attribute "bugsnag.system.cpu_mean_total" is greater than 0.0
    * the span named "DiskIopsIsolation" array attribute "bugsnag.system.memory.timestamps" is not empty
    * span integer attribute "bugsnag.system.memory.spaces.device.size" should be greater than 0
    * every span attribute "bugsnag.system.disk.iops_read" does not exist
    * every span attribute "bugsnag.system.disk.iops_write" does not exist
    * every span attribute "bugsnag.system.disk.iops_total" does not exist

  # ==========================================================================
  # ROAD 2233 - Scenario 14
  # Backend span_count / percentiles are out of scope. Maze delivers one
  # batch containing a disk-reporting span and a disk-omitted span
  # ==========================================================================
  Scenario: Mixed disk-on and disk-off spans are delivered in one batch
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure bugsnag "cpuMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "mixed_mode" to "true"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 2 spans
    Then a span field "name" equals "DiskIopsNewSdk"
    * a span field "name" equals "DiskIopsOldSdk"
    * the span named "DiskIopsNewSdk" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "DiskIopsNewSdk" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * the span named "DiskIopsNewSdk" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"
    * the span named "DiskIopsNewSdk" array attribute "bugsnag.system.cpu_measures_total" is not empty
    * the span named "DiskIopsOldSdk" attribute "bugsnag.system.disk.iops_read" does not exist
    * the span named "DiskIopsOldSdk" attribute "bugsnag.system.disk.iops_write" does not exist
    * the span named "DiskIopsOldSdk" attribute "bugsnag.system.disk.iops_total" does not exist
    * the span named "DiskIopsOldSdk" array attribute "bugsnag.system.cpu_measures_total" is not empty

  # ==========================================================================
  # ROAD 2233 - Scenario 15
  # Maze's mock trace API accepts the payload (receiving the span proves
  # HTTP delivery); exact ROAD values (18/16/34) are not producible on real
  # hardware and stay documentation-only.
  # ==========================================================================
  Scenario: SDK delivers a disk IOPS span payload to the trace API
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "1.0"
    And I configure scenario "disk_work_bytes" to "1048576"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "span_name" to "DiskIopsCustom"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then the trace "Content-Type" header equals "application/json"
    * a span field "name" equals "DiskIopsCustom"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0

  # ==========================================================================
  # iOS-specific additional coverage (beyond the shared ROAD scenarios)
  # ==========================================================================

  # Default configuration state: disk metrics are off out of the box.
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

  # Tri-state eligibility: first-class spans opt in by default.
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

  # Tri-state eligibility: non-first-class spans are excluded by default.
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

  # Tri-state eligibility: the per-span override widens eligibility.
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

  # Tri-state eligibility: the per-span override narrows eligibility.
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

  # Very short span (tiny-denominator guard): real forced I/O inside a span
  # well under 100ms must still produce integer, non-negative, internally
  # consistent values.
  Scenario: A very short span with real disk activity produces valid disk IOPS values
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "span_duration" to "0.05"
    And I configure scenario "opts_first_class" to "yes"
    And I configure scenario "span_name" to "DiskIopsShortSpan"
    And I configure scenario "workload" to "write"
    And I configure scenario "workload_bytes" to "262144"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 1 span
    Then a span field "name" equals "DiskIopsShortSpan"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_total" should be greater than or equal to 0
    * the span named "DiskIopsShortSpan" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"
