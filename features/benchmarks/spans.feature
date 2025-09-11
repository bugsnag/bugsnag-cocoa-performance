Feature: Device Metrics

  Scenario Outline:
    When I run "SpanOpenCloseSuite" configured as <options>
    And I wait for 30 seconds
    And I wait to receive at least 1 metrics
    And I discard the oldest metric

    Examples:
      | options                          |
      | ""                               |
      | "rendering"                      |
      | "cpu"                            |
      | "memory"                         |
      | "NamedSpan"                      |
      | "rendering cpu memory"           |
      | "rendering cpu memory NamedSpan" |