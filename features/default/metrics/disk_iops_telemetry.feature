Feature: Disk IOPS

  # iOS ground truth (BSGDiskIOCollector.mm / OtlpTraceEncoding.mm):
  # - Attribute keys: bugsnag.system.disk.iops_read / iops_write / iops_total
  #   this file asserts the keys the iOS SDK actually emits. ***
  # - Values are int64 exported as OTLP intValue (NaN/Infinity unrepresentable).
  # - Gating: enabledMetrics.disk (default NO) AND span-level tri-state
  #   metricsOptions.disk (unset -> first-class spans only).
  # - No OS-version floor: proc_pid_rusage and statfs exist on every supported
  #   iOS version, so this file runs across the whole BitBar device matrix.
  # - The SDK emits no internal debug attributes (bugsnag.internal.*).

  # ==========================================================================
  # ROAD 2233 - Scenario 1
  # SDK emits all 3 disk IOPS attributes as IntValue on eligible spans.
  #
  # iOS app_start spans begin BEFORE BugsnagPerformance.start() (pre-main),
  # when no start snapshot can exist, so they never carry disk attributes by
  # design and no app_start row is run.
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

  # ==========================================================================
  # ROAD 2233 - Scenario 2
  # SDK reports real disk IOPS values computed on the device: integers >= 0
  # and total = read + write.
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
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_total" is greater than or equal to 0
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

    Examples:
      | platform | span_type   | span_name             |
      | ios      | custom      | DiskIopsCustom        |
      | ios      | app_session | [AppSession/DiskIops] |

  # ==========================================================================
  # ROAD 2233 - Scenario 7b
  # Multiple sequential spans capture independent disk metrics: consecutive
  # spans each capture a fresh snapshot (no stale start counters). Each span
  # is asserted independently for valid, internally consistent values.
  # ==========================================================================
  Scenario: Multiple sequential spans capture independent disk metrics
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "sequential_mode" to "true"
    And I start bugsnag
    And I run the loaded scenario
    And I wait for exactly 2 spans
    Then a span field "name" equals "DiskIopsSequential1"
    * a span field "name" equals "DiskIopsSequential2"
    * the span named "DiskIopsSequential1" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "DiskIopsSequential1" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * the span named "DiskIopsSequential1" integer attribute "bugsnag.system.disk.iops_total" is greater than or equal to 0
    * the span named "DiskIopsSequential1" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"
    * the span named "DiskIopsSequential2" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "DiskIopsSequential2" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * the span named "DiskIopsSequential2" integer attribute "bugsnag.system.disk.iops_total" is greater than or equal to 0
    * the span named "DiskIopsSequential2" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

  # ==========================================================================
  # ROAD 2233 - Scenario 9
  # Disk IOPS across app lifecycle transitions, for custom and app-session
  # spans. Constraints forced by SDK design (abortOpenSpansOnBackground aborts
  # every open non-app-session span when the app backgrounds):
  #  - mid-span transition must use an app-session span (the only survivor);
  #  - "ends while in background" requires the span to also START in the
  #    background (a span merely open at the transition is aborted);
  #  - the app-termination row is omitted (no next-launch assertion harness).
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
  Scenario Outline: SDK captures disk IOPS for a span that ends while in the background
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "lifecycle_mode" to "start_end_in_background"
    And I configure scenario "span_type" to "<span_type>"
    And I configure scenario "span_name" to "DiskIopsCustom"
    And I start bugsnag
    And I run the loaded scenario
    And I switch to the web browser for 3 seconds
    And I wait for exactly 1 span
    Then a span field "name" equals "<span_name>"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

    Examples:
      | platform | span_type   | span_name             |
      | ios      | custom      | DiskIopsCustom        |
      | ios      | app_session | [AppSession/DiskIops] |

  # Row: background -> foreground (span starts in background, ends in foreground).
  Scenario Outline: SDK captures disk IOPS for a span that starts in the background
    Given I load scenario "DiskIOPSScenario"
    And I configure bugsnag "diskMetrics" to "true"
    And I configure scenario "run_delay" to "0"
    And I configure scenario "lifecycle_mode" to "start_in_background"
    And I configure scenario "span_type" to "<span_type>"
    And I configure scenario "span_name" to "DiskIopsCustom"
    And I start bugsnag
    And I run the loaded scenario
    And I switch to the web browser for 2 seconds
    And I wait for exactly 1 span
    Then a span field "name" equals "<span_name>"
    * span integer attribute "bugsnag.system.disk.iops_read" should be greater than or equal to 0
    * span integer attribute "bugsnag.system.disk.iops_write" should be greater than or equal to 0
    * the span named "<span_name>" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

    Examples:
      | platform | span_type   | span_name             |
      | ios      | custom      | DiskIopsCustom        |
      | ios      | app_session | [AppSession/DiskIops] |

  # ==========================================================================
  # ROAD 2233 - Scenario 10
  # Spans from an SDK with disk metrics disabled omit iops_* even when the
  # span-level metrics option asks for disk.
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
  # High and burst I/O produce valid Int64 values (intValue typing makes
  # NaN/Infinity unrepresentable; the integer steps only match intValue).
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
    * the span named "DiskIopsWorkload" integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * the span named "DiskIopsWorkload" integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * the span named "DiskIopsWorkload" integer attribute "bugsnag.system.disk.iops_total" is greater than or equal to 1
    * the span named "DiskIopsWorkload" integer attribute "bugsnag.system.disk.iops_total" equals the sum of integer attributes "bugsnag.system.disk.iops_read" and "bugsnag.system.disk.iops_write"

    Examples:
      | platform | workload    | duration_sec | workload_bytes |
      | ios      | sqlite      | 2.0          | 0              |
      | ios      | burst_write | 10.0         | 10485760       |
      | ios      | file_copy   | 5.0          | 52428800       |

  # ==========================================================================
  # ROAD 2233 - Scenario 12
  # OTLP payload structure: the three iops_* keys with intValue encoding
  # (the integer steps only match intValue entries) and no legacy or raw keys.
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
    * the span named "DiskIopsCustom" has exactly 3 attributes whose keys start with "bugsnag.system.disk.iops_"
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
  # disabled.
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
  # Mixed SDK versions - partial disk IOPS coverage: one batch containing a
  # disk-reporting span and a disk-omitted span.
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
    * the trace payload field "resourceSpans.0.resource" string attribute "telemetry.sdk.name" equals "bugsnag.performance.cocoa"
