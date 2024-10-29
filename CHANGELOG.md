Changelog
=========

## TBD

### Bug fixes

* Set bugsnag.span.category to 'custom' for custom spans.
  [336](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/336)

* Fixed a crash after shared NSURLSession invalidate
  [334](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/334)

* Fix visionOS compilation errors. Note that visionOS is not yet officially supported.
  [327](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/327)

## 1.10.0 (2024-09-30)

### Enhancements

* Added rendering metrics to first class spans.
  [319](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/319)

## 1.9.0 (2024-09-25)

### Enhancements

* Added configurable limit to number of span attributes per span.
  [315](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/315)

* Added configurable span attribute limits for string and array types.
  [314](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/314)

### Bug fixes

* Make sure that no early network spans escape when automatic network span capture is disabled.
  [317](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/317)

* Add missing / misnamed fields to plist configuration.
  [316](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/316)

## 1.8.1 (2024-09-03)

### Bug fixes

* Stop podspec from trying to compile xcprivacy files (which generates warnings).
  [311](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/311)

* Early spans (ended before Bugsnag starts) now get their sampling probability value properly updated.
  [310](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/310)

* Release process now updates BugsnagPerformanceSwift podspec rather than BugsnagPerformanceSwiftUI (which has been deprecated)
  [308](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/308)

* Use API key subdomain as default Performance endpoint
  [313](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/313)

## 1.8.0 (2024-08-29)

### Enhancements

* `service.name` can now be set in the configuration.
  [299](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/299)
  
* A fixed `samplingProbability` can now be set in the configuration.
  [300](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/300)

* OnEnd span callbacks are now called on early spans (spans that ended before library start) once the library is started.
  [298](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/298)

## 1.7.0 (2024-08-05)

### Enhancements

* Span attributes can now be set by the user.
  [286](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/286)

* Array-of-primitives span attributes are now supported.
  [288](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/288)

* OnEnd span callbacks can now be registered in the configuration. These callbacks are called on all sampled spans.
  [289](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/289)

### Bug fixes

* Added more autoreleasepools to catch potential memory leaks, and fixed a retain loop in BugsnagPerformanceSpan.
  [293](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/293)

* Rename propagateTraceParentToUrlsMatching to the intended tracePropagationUrls in BugsnagPerformanceConfiguration.
  [287](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/287)

* Workaround for Swift namespacing issue that caused conflicts when BugsnagPerformanceSwift was built as an xcframework.
  [284](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/284)

## 1.6.2 (2024-07-04)

### Bug fixes

* Handle case where the user manually sets the network callback to nil. [281](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/281)

### Enhancements

* Span parentage APIs now take a BugsnagPerformanceSpanContext, which BugsnagPerformanceSpan is now a subclass of. You no longer need to assign a BugsnagPerformanceSpan as a parent. [280](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/280)

## 1.6.1 (2024-06-24)

### Bug fixes

* Fixed a crash on reportNetworkRequestSpan when networkRequestCallback is not set in the configuration. [277](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/277)

## 1.6.0 (2024-06-11)

### Enhancements

* Auto-inject OTLP traceparent headers into network requests sent via URLSession. [259](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/259)

* Added support for trace and span IDs to be added to bugsnag-cocoa error notifications if the library is present. [263](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/263)

### Bug fixes

* When we detect a long delay after viewDidLayoutSubviews where viewDidAppear still hasn't been called, assume that this edge case has been triggered and use the time of viewDidLayoutSubviews instead. [257](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/257)

* Detect app backgrounding earlier to detect interrupted app starts and cancel their spans (which would otherwise be VERY long). [262](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/262)

* Workaround for badly behaved NSURLSessionTask classes to avoid a crash. [267](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/267)

* Removed duplicate makeCurrentContext check that was leading to a memory leak. [268](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/268)

## 1.5.0 (2024-03-18)

### Enhancements

* Add package BugsnagPerformanceSwift, and deprecate package BugsnagPerformanceSwiftUI.
  [251](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/251)

* Add API to support UIViewControllers that use generics
  [250](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/250)

### Bug fixes

* Guard against an edge case where an auto-captured URL request with a nil URL can crash the library if it's sent before Bugsnag is initialized.
  [253](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/253)

## 1.4.1 (2024-02-28)

### Bug fixes

* Use ObjC strings instead of C strings to avoid ASAN lifetime race condition
  [247](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/247)

* Fixed the issue causing PrivacyInfo collisions when using Cocoapods
  [246](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/246)

## 1.4.0 (2024-01-31)

### Enhancements

* swizzleViewLoadPreMain setting is now false by default. When this config value is true, all custom view controllers are swizzled at app start, which may delay app start if there are many of them.
  [202](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/202)

* Detect pre-loaded views and correct their durations. These can occur in container views, such as `UITabViewController` when the view is loaded in anticipation of the user opening the next tab. The resulting spans are now marked with a "pre-loaded" suffix and the timings adjusted to start from `viewWillAppear` only. 
  [236](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/236)

### Bug fixes

* Use recursive mutexes in places that might be reentrantly accessed.
  [242](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/242)

* Fix for potential incorrect span list size due to race condition.
  [238](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/238)

* Ensure that swizzled method return values are always propagated correctly.
  [202](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/202)

## 1.3.0 (2024-01-04)

### Enhancements

* Added support for deferring view load span end
  [230](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/230)

* Discard unfinished spans when the app goes into the background
  [228](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/228)

## 1.2.0 (2023-12-06)

This release increases the minimum supported iOS version of the library from 11 to 13.

### Enhancements

* Added support for instrumenting SwiftUI views
  [222](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/222)

## 1.1.3 (2023-11-23)

### Enhancements

* Added [privacy manifest](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files) to declare data use and required reasons for API usage
  [212](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/212)

* Detect app prewarming and discard any view load spans that would be distorted by it. 
  [211](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/211)

### Bug fixes

* Fetching of network swizzle targets is now done on a BG queue in order to avoid a potential deadlock 
  [218](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/218)

* Ensure span cancellation is done with concurrency protection 
  [217](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/217)

## 1.1.2 (2023-10-19)

### Bug fixes

* Renamed "AppStart/Cold" to "AppStart/iOSCold", and "AppStart/Warm" to "AppStart/iOSWarm"
  [207](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/207)

* Fixed some subtle swizzling bugs and harmonized all swizzling code
  [206](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/206)

## 1.1.1 (2023-08-28)

### Enhancements

* Reduced impact on application launch time
  [197](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/197)

## 1.1.0 (2023-07-27)

### Enhancements

* Network spans can now be controlled via user callbacks
  [189](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/189)
  
### Bug fixes

* The span sampling attribute was not being set when equal to 1.0
  [195](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/195)

## 1.0.0 (2023-07-17)

### Bug fixes

* Perform end time calculation using signed ints to prevent unsigned overflow
  [187](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/187)

* Don't retry sending payloads that are over 1MB
  [185](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/185)

* Cover every potential race condition in span attributes with a mutex
  [184](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/184)

## 0.8.0 (2023-07-10)

### Enhancements

* Update persistent device id code to match bugsnag-cocoa
  [177](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/177)

### Bug fixes

* Removed duplicate ViewLoadPhase spans
  [182](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/182)

* Fixed ViewLoadPhase spans parentage
  [181](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/181)

## 0.7.0 (2023-06-26)

### Breaking changes

The following changes need attention when updating to this version of the library:

* Remove public access to the samplingProbability config option because it gets too confusing when mixed with server-side P values.
  [174](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/174)
  
### Enhancements

* Loading the complete config from Info.plist
  [166](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/166)
  
* Store generated device ID and share it with the next release of bugsnag-cocoa
  [171](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/171)
  
### Bug fixes

* Removed logging [ViewLoadPhase/loadView] spans for ViewControllers that don't call loadView
  [172](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/172)
  
* Network spans will no longer be parents of other spans
  [175](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/175)

## 0.6.0 (2023-06-15)

### Breaking changes

The following changes need attention when updating to this version of the library:

* Replaced the constructor of BugsnagPerformanceSpanOptions with chained setters
  [161](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/161)
  
### Enhancements

* Added `appVersion` and `bundleVersion` to `BugsnagPerformanceConfiguration`.
  [162](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/162)
  
* Added `startWithApiKey` to `BugsnagPerformance`.
  [165](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/165)
  
### Bug fixes

* Added subseconds to iso8601 dates even on ios 11.
  [159](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/159)
  
* Fixed new warnings in Xcode 14.3
  [163](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/163)
  
* Fixed incorrect ui span start time
  [168](https://github.com/bugsnag/bugsnag-cocoa-performance/pull/168)

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
