Upgrading Guide
===============

Upgrade from 1.X to 2.X
-----------------------

### Key points

- Initial view load is now included in app starts (See docs: [iOS](https://docs.bugsnag.com/performance/integration-guides/ios/#instrumenting-app-starts))
- App starts can now be categorized (See docs: [iOS](https://docs.bugsnag.com/performance/integration-guides/ios/#app-start-types))
- Pre-loaded view loads are be split into `pre-load` and `presenting` phases (See docs: [iOS](https://docs.bugsnag.com/performance/integration-guides/ios/#https://docs.bugsnag.com/performance/integration-guides/ios/#pre-loaded-views))
- View load end can now be deferred by using loading indicators (See docs: [iOS](https://docs.bugsnag.com/performance/integration-guides/ios/#loading-indicators))
- Introduced Debug mode which reduces batch time (See docs: [iOS](https://docs.bugsnag.com/performance/integration-guides/ios/#debug-mode))

More details of these changes can be found below and full documentation is available online:
[iOS](https://docs.bugsnag.com/performance/integration-guides/ios/)

### Configuration

#### Additions

The following options have been added to the `BugsnagPerformanceConfiguration` class: 

| Property/Method                                                    | Usage                                                             |
| ------------------------------------------------------------------ | ----------------------------------------------------------------- |
| `autoInstrumentAppStartsLegacy` | Restores app starts measurement behaviour from v1.X. (See docs: [iOS](https://docs.bugsnag.com/platforms/ios/customizing-breadcrumbs/#legacy-app-starts))
| `debugMode` | Turns on Debug mode which reduces batch time (See docs: [iOS](https://docs.bugsnag.com/performance/integration-guides/ios/#debug-mode))

### App starts

#### Additions

App start spans will now include rendering, cpu and memory metrics.

You can categorize your app starts further, for example to track the app start period for logged-in users separately to new users.

To set the app start type, use the following code during the app start period:
<% partial "platforms/inline_code_switcher" do %>
```objc
    BugsnagPerformanceAppStartSpanQuery *appStartTypeQuery = [BugsnagPerformanceAppStartSpanQuery query];
    BugsnagPerformanceAppStartSpanControl *spanControl = [BugsnagPerformance getSpanControlsWithQuery:appStartTypeQuery];
    if (spanControl != nil) {
        [spanControl setType:@"logged-in-user"];
    }
```
```swift
    let query = BugsnagPerformanceAppStartSpanQuery()
    let spanControl = BugsnagPerformance.getSpanControls(with: query) as! BugsnagPerformanceAppStartSpanControl?
    spanControl?.setType("logged-in-user")
```
<% end %>

#### Changes

Initial view load will now be included in app start time. This is enabled by default. If you want to disable this feature, you can use app starts legacy mode.

To enable legacy app start instrumentation, set the `autoInstrumentAppStartsLegacy` configuration option:
<% partial "platforms/inline_code_switcher" do %>
```objc
BugsnagPerformanceConfiguration *config = [BugsnagPerformanceConfiguration loadConfig];
config.autoInstrumentAppStartsLegacy = YES;
[BugsnagPerformance startWithConfiguration:config];
```
```swift
let config = BugsnagPerformanceConfiguration.loadConfig()
config.autoInstrumentAppStartsLegacy = true
BugsnagPerformance.start(configuration: config)
```
<% end %>

For full details, see the online docs:
[iOS](https://docs.bugsnag.com/performance/integration-guides/ios/#instrumenting-app-starts)

### Loading indicators

#### Additions

To track the loading time of the data you can use the new `BugsnagPerformanceLoadingIndicatorView` class. All you need to do is add a loading indicator view to the hierarchy. You can do that by either making the root view a subclass of `BugsnagPerformanceLoadingIndicatorView` or adding a `BugsnagPerformanceLoadingIndicatorView` as a subview. The loading phase will be marked as finished automatically when the view dissapears. You can also mark the finish manually by calling `finishLoading` method.

<% partial "platforms/inline_code_switcher" do %>
```objc
@interface CustomViewController ()

@property(nonatomic) BugsnagPerformanceLoadingIndicatorView *loadingIndicator;

@end

@implementation CustomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loadingIndicator = [BugsnagPerformanceLoadingIndicatorView new];
    [self.view addSubview:self.loadingIndicator];
}

- (void)finishLoading {
    [self.loadingIndicator finishLoading];
}

@end
```
```swift
class CustomViewController: UIViewController {
    var loadingIndicator: BugsnagPerformanceLoadingIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadingIndicator = BugsnagPerformanceLoadingIndicatorView()
        view.addSubview(loadingIndicator)
    }

    func finishLoading() {
        loadingIndicator.finishLoading()
    }
}
```
<% end %>

### Plugin context

#### Changes

The following changes have been made to the `BugsnagPerformancePluginContext` class:

| v1.x API                                                           | v2.x API                                                          |
| ------------------------------------------------------------------ | ----------------------------------------------------------------- |
| `cofiguration`                                                     | `configuration`                                                   |

