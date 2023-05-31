Changelog
=========

## 0.5.0 (2023-05-31)

### Breaking changes

The following changes need attention when updating to this version of the library:

* Improved span starting and ending performance
  [151](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/151)
  
* Fixed a date formatter crash on iOS 11.0 and 11.1
  [155](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/155)
  
### Enhancements

* Added view_load_phase spans
  [143](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/143)

### Bug fixes

* Fixed a crash in the `SpanAttributesProvider.mm`
  [153](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/153)

## 0.4.0 (2023-05-25)

### Breaking changes

The following changes need attention when updating to this version of the library:

* Renamed incorrectly named `makeContextCurrent` to `makeCurrentContext` in rest of the codebase
  [139](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/139)

### Bug fixes

* Removed C++ code from public headers
  [147](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/147)

* Protect against multithreaded span attributes access
  [146](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/146)

* Don't send network spans for failed requests
  [140](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/140)

* Don't capture file:// URLRequests
  [138](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/138)

## 0.3.1 (2023-05-10)

### Bug fixes

* Fix incorrect swizzle of `viewWillDisappear`
  [134](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/134) ([AniHovhannisyanAni](https://github.com/AniHovhannisyanAni))

## 0.3.0 (2023-05-09)

### Breaking changes

The following changes need attention when updating to this version of the library:

* Renamed incorrectly named `makeContextCurrent` to `makeCurrentContext` in `BugsnagPerformanceSpanOptions`
  [128](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/128)

### Enhancements

* Swizzle methods earlier at process start rather than at library start to avoid race conditions. Swizzling can now be disabled using `bugsnag/performance/disableSwizzling` in your `Info.plist`
  [126](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/126)

### Bug fixes

* Fix potential race condition in accessing NSURLSessionTaskMetrics.transactionMetrics
  [130](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/130)

## 0.2.3 (2023-05-03)

### Bug fixes

* Temporary Fix: Disable swizzling of `viewWillDisappear` while we work on a better solution
  [124](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/124)

## 0.2.2 (2023-04-27)

### Bug fixes

* Fix: Incorrectly named span attribute: `view_load` -> `view_load_phase`
  [122](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/122)

* Fix: Start network spans at the point that the network request starts rather than at the end (to ensure proper parentage)
  [119](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/119)

## 0.2.1 (2023-04-26)

### Bug fixes

* Fix: Doubles were erroneously converted to strings
  [120](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/120)

## 0.2.0 (2023-04-24)

This release adds nested span support.

### Breaking changes

The following changes need attention when updating to this version of the library:

* Corrected name of `autoInstrumentNetworkRequests` configuration option (was previously `autoInstrumentNetwork`)
  [112](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/112)

* Applied updated span and attribute naming (causes duplicate aggregations in your dashboard of App Start, Screen Load and Network spans from previous versions)
  [111](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/111)

### Enhancements

* Added connection.subtype attribute to network spans
  [109](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/109)

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
