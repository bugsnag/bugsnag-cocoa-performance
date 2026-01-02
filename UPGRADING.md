Upgrading Guide
===============

Upgrade from 1.X to 2.X
-----------------------

V2 of the Bugsnag Performance iOS SDK makes several changes to the way app starts and view loads are instrumented. This guide explains what changes you will see to your performance timings once you have upgraded and the configuration options available to control this.

### Key points

- The initial view load is now included in app start timings (see [docs](https://docs.bugsnag.com/performance/integration-guides/ios/#instrumenting-app-starts))
- The end of view loads can now be deferred to account of asynchronous actions using loading indicators (see [docs](https://docs.bugsnag.com/performance/integration-guides/ios/#loading-indicators))
- App starts can now be categorized to separate different types of start (see [docs](https://docs.bugsnag.com/performance/integration-guides/ios/#app-start-types))
- App starts and view loads can now report their rendering, CPU and memory metrics (see [docs](https://docs.bugsnag.com/performance/integration-guides/ios/#capturing-system-metrics))
- Pre-loaded views, such as hidden `UITabViewController` tabs, are split into `pre-load` and `presenting` phases (see [docs](https://docs.bugsnag.com/performance/integration-guides/ios/#pre-loaded-views))

### App start duration changes

The initial view load will now be included in app start time. This brings our iOS SDK in line with other BugSnag Performance SDKs and provides a more accurate representation of the user experience when launching the app.

You will therefore see an increase in app start duration when upgrading from v1.x to v2.x of the SDK. We recommend using this measurement, however if you wish to maintain the previous behavior for a period of time you can do so by enabling legacy app start instrumentation in configuration:

```swift
let config = BugsnagPerformanceConfiguration.loadConfig()
config.autoInstrumentAppStartsLegacy = true
BugsnagPerformance.start(configuration: config)
```

Note – this option will likely be removed in a future major version of the SDK.

### Loading indicators

By default, view load timings will end when the view's `viewDidAppear` method is called. However, if your view performs asynchronous work during loading (e.g. fetching data from a network) you may wish to defer the end of the view load until this work is complete.

In v2 this is achieved by adding loading indicators to your view hierarchy in either UIKit or SwiftUI. These are invisible view components which signal to the SDK that loading is still in progress. The view load – and app start, if still in progress – will only end when all loading indicators have been removed from the view hierarchy or have been marked as finished.

See the [docs](https://docs.bugsnag.com/performance/integration-guides/ios/#loading-indicators) for more information.

### Plugin context interface

The following changes have been made to the `BugsnagPerformancePluginContext` class:

| v1.x API                                                           | v2.x API                                                          |
| ------------------------------------------------------------------ | ----------------------------------------------------------------- |
| `cofiguration`                                                     | `configuration`                                                   |
