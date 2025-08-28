//
//  ViewLoadInstrumentation.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 10/10/2022.
//

#import <UIKit/UIKit.h>
#import "../../PhasedStartup.h"
#import "../../Tracer.h"
#import "State/ViewLoadInstrumentationState.h"
#import "SpanFactory/ViewLoadSpanFactory.h"
#import "System/ViewLoadInstrumentationSystemUtils.h"
#import "System/ViewLoadSwizzlingHandler.h"
#import "Lifecycle/ViewLoadLifecycleHandler.h"

#import <vector>

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {
class ViewLoadInstrumentation: public PhasedStartup {
public:
    ViewLoadInstrumentation(std::shared_ptr<ViewLoadInstrumentationSystemUtils> systemUtils,
                            std::shared_ptr<ViewLoadSwizzlingHandler> swizzlingHandler,
                            std::shared_ptr<ViewLoadLifecycleHandler> lifecycleHandler) noexcept
    : isEnabled_(true)
    , systemUtils_(systemUtils)
    , swizzlingHandler_(swizzlingHandler)
    , lifecycleHandler_(lifecycleHandler)
    {}

    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept {};
    void start() noexcept {}
    
    void loadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingIndicatorView) noexcept;
    void loadingIndicatorWasRemoved(BugsnagPerformanceLoadingIndicatorView *loadingIndicatorView) noexcept;
    
private:
    std::shared_ptr<ViewLoadInstrumentationSystemUtils> systemUtils_;
    std::shared_ptr<ViewLoadSwizzlingHandler> swizzlingHandler_;
    std::shared_ptr<ViewLoadLifecycleHandler> lifecycleHandler_;
    
    bool isEnabled_{true};
    bool swizzleViewLoadPreMain_{true};
    BOOL (^ _Nullable callback_)(UIViewController *viewController){nullptr};
    
    ViewLoadSwizzlingCallbacks *createViewLoadSwizzlingCallbacks() noexcept;
    bool canCreateSpans(UIViewController *viewController) noexcept;

    void updateViewForViewController(UIViewController *viewController, ViewLoadInstrumentationState *instrumentationState);
};
}

NS_ASSUME_NONNULL_END
