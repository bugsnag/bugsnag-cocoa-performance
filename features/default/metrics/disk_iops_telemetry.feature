Feature: Spans with collected Disk IOPS metrics

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
    * a span integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * a span integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * a span integer attribute "bugsnag.system.disk.iops_total" is greater than or equal to 0

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
    * a span integer attribute "bugsnag.system.disk.iops_read" is greater than or equal to 0
    * a span integer attribute "bugsnag.system.disk.iops_write" is greater than or equal to 0
    * a span integer attribute "bugsnag.system.disk.iops_total" is greater than or equal to 0

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

