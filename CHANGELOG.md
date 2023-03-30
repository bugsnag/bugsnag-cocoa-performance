Changelog
=========

## TBD

### Enhancements

* Added first_view_name attribute to app start spans
  [91](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/91)

## 0.1.5 (2023-03-22)

### Bug fixes

* Use app-extension safe version of UIApplication.sharedApplication
  [82](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/82)

## 0.1.4 (2023-03-20)

### Enhancements

* Added enabledReleaseStages to BugsnagPerformanceConfiguration.
  [78](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/78)
  
### Bug fixes

* Fixed compile issue with mac catalyst targets.
  [79](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/79)

## 0.1.3 (2023-03-17)

### Bug fixes

* Turn up all warnings and sanitizers to 11, and fix detected UB behavior.
  [76](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/76)
  [74](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/74)
  [73](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/73)

* Safer background/foreground detection.
  [72](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/72)

* Corrected boot time fetch code.
  [70](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/70)

## 0.1.2 (2023-03-15)

### Bug fixes

* Restructure the example app for preview release.
  [66](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/66)

## 0.1.1 (2023-03-14)

### Bug fixes

* Revert to simple Bugsnag.start API as originally envisioned.
  [64](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/64)

* Make sure span drain occurs on transition from BG to FG.
  [63](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/63)

* Fixed periodic span drain that wasn't occurring.
  [62](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/62)

## 0.1.0

Initial preview release
