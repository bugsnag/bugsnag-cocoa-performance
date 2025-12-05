Feature: Spans with collected frame metrics

  Scenario: Frame metrics - no slow frames
    Given I run "FrameMetricsNoSlowFramesScenario"
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * every span field "name" equals "FrameMetricsNoSlowFramesScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span integer attribute "bugsnag.rendering.total_frames" is greater than 0
    * a span integer attribute "bugsnag.rendering.slow_frames" equals 0
    * a span integer attribute "bugsnag.rendering.frozen_frames" equals 0

  Scenario: Frame rendering metrics - normal start, no slow frames
    Given I load scenario "RenderingMetricsScenario"
    And I configure bugsnag "renderingMetrics" to "true"
    And I set the sampling probability to "1.0"
    And I configure scenario "variant_name" to "NoSlow"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * every span field "name" equals "RenderingMetricsScenarioNoSlow"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span integer attribute "bugsnag.rendering.total_frames" is greater than 0
    * a span integer attribute "bugsnag.rendering.slow_frames" equals 0
    * a span integer attribute "bugsnag.rendering.frozen_frames" equals 0

  Scenario: Frame rendering metrics - early start, no slow frames
    Given I load scenario "RenderingMetricsScenario"
    And I configure bugsnag "renderingMetrics" to "true"
    And I configure scenario "spanStartTime" to "early"
    And I configure scenario "variant_name" to "EarlyStart"
    And I set the sampling probability to "1.0"
    And I start bugsnag
    And I run the loaded scenario
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * every span field "name" equals "RenderingMetricsScenarioEarlyStart"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span integer attribute "bugsnag.rendering.total_frames" is greater than 0
    * a span integer attribute "bugsnag.rendering.slow_frames" equals 0
    * a span integer attribute "bugsnag.rendering.frozen_frames" equals 0

  Scenario: Frame metrics - slow frames
    Given I run "FrameMetricsSlowFramesScenario"
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * every span field "name" equals "FrameMetricsSlowFramesScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * a span integer attribute "bugsnag.rendering.total_frames" is greater than 0
    * a span integer attribute "bugsnag.rendering.slow_frames" equals 3
    * a span integer attribute "bugsnag.rendering.frozen_frames" equals 0

  Scenario: Frame metrics - frozen frames
    Given I run "FrameMetricsFronzenFramesScenario"
    And I wait to receive at least 3 spans
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:3"
    * a span field "name" equals "FrameMetricsFronzenFramesScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * a span bool attribute "bugsnag.span.first_class" is true
    * a span integer attribute "bugsnag.rendering.total_frames" is greater than 4
    * a span integer attribute "bugsnag.rendering.slow_frames" equals 2
    * a span integer attribute "bugsnag.rendering.frozen_frames" equals 2
    * the span named "FrameMetricsFronzenFramesScenario" is the parent of every span named "FrozenFrame"

  Scenario: Frame metrics - autoInstrumentRendering off
    Given I run "FrameMetricsAutoInstrumentRenderingOffScenario"
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * every span field "name" equals "FrameMetricsAutoInstrumentRenderingOffScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span integer attribute "bugsnag.rendering.total_frames" does not exist
    * every span integer attribute "bugsnag.rendering.slow_frames" does not exist
    * every span integer attribute "bugsnag.rendering.frozen_frames" does not exist

  Scenario: Frame metrics - span instrumentRendering off
    Given I run "FrameMetricsSpanInstrumentRenderingOffScenario"
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * every span field "name" equals "FrameMetricsSpanInstrumentRenderingOffScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is true
    * every span integer attribute "bugsnag.rendering.total_frames" does not exist
    * every span integer attribute "bugsnag.rendering.slow_frames" does not exist
    * every span integer attribute "bugsnag.rendering.frozen_frames" does not exist

  Scenario: Frame metrics - non firstClass span with instrumentRendering off
    Given I run "FrameMetricsNonFirstClassSpanInstrumentRenderingOnScenario"
    And I wait to receive at least 1 span
    Then the trace "Content-Type" header equals "application/json"
    * the trace "Bugsnag-Span-Sampling" header equals "1:1"
    * every span field "name" equals "FrameMetricsNonFirstClassSpanInstrumentRenderingOnScenario"
    * every span field "spanId" matches the regex "^[A-Fa-f0-9]{16}$"
    * every span field "traceId" matches the regex "^[A-Fa-f0-9]{32}$"
    * every span field "kind" equals 1
    * every span bool attribute "bugsnag.span.first_class" is false
    * a span integer attribute "bugsnag.rendering.total_frames" is greater than 0
    * a span integer attribute "bugsnag.rendering.slow_frames" equals 3
    * a span integer attribute "bugsnag.rendering.frozen_frames" equals 0
