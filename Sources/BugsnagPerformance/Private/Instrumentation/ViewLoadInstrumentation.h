//
//  ViewLoadInstrumentation.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 10/10/2022.
//

#import <UIKit/UIKit.h>
#import "../PhasedStartup.h"
#import "../Tracer.h"

#import <vector>

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {
class ViewLoadInstrumentation: public PhasedStartup {
public:
    ViewLoadInstrumentation(std::shared_ptr<Tracer> tracer, std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
    : isEnabled_(true)
    , isEarlySpanPhase_(true)
    , tracer_(tracer)
    , spanAttributesProvider_(spanAttributesProvider)
    , earlySpans_([NSMutableArray new])
    {}

    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void start() noexcept {}
    
private:
    static std::vector<const char *> imagesToInstrument() noexcept;
    static std::vector<Class> viewControllerSubclasses(const char *image) noexcept;
    static bool isViewControllerSubclass(Class subclass) noexcept;
    
    void instrument(Class cls) noexcept;
    void instrumentLoadView(Class cls) noexcept;
    void instrumentViewDidLoad(Class cls) noexcept;
    void instrumentViewWillAppear(Class cls) noexcept;
    void instrumentViewDidAppear(Class cls) noexcept;
    void instrumentViewWillDisappear(Class cls) noexcept;
    void instrumentViewWillLayoutSubviews(Class cls) noexcept;
    void instrumentViewDidLayoutSubviews(Class cls) noexcept;

    void onLoadView(UIViewController *viewController) noexcept;
    void onViewDidAppear(UIViewController *viewController) noexcept;
    void onViewWillDisappear(UIViewController *viewController) noexcept;
    void endViewLoadSpan(UIViewController *viewController) noexcept;
    void endViewAppearingSpan(UIViewController *viewController) noexcept;
    void endSubviewsLayoutSpan(UIViewController *viewController) noexcept;
    BugsnagPerformanceSpan *startViewLoadPhaseSpan(UIViewController *viewController, NSString *phase) noexcept;

    void markEarlySpan(BugsnagPerformanceSpan *span) noexcept;
    void endEarlySpanPhase() noexcept;
    bool canCreateSpans(UIViewController *viewController) noexcept;
    bool isClassObserved(Class cls) noexcept;

    bool isEnabled_{true};
    bool swizzleViewLoadPreMain_{true};
    std::shared_ptr<Tracer> tracer_;
    BOOL (^ _Nullable callback_)(UIViewController *viewController){nullptr};
    std::map<Class, bool> classToIsObserved_{};
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::atomic<bool> isEarlySpanPhase_{true};
    std::mutex earlySpansMutex_;
    NSMutableArray<BugsnagPerformanceSpan *> * _Nullable earlySpans_;
    std::mutex vcInitMutex_;
};
}

NS_ASSUME_NONNULL_END
