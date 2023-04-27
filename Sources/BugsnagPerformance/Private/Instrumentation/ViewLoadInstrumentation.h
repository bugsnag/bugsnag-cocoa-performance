//
//  ViewLoadInstrumentation.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 10/10/2022.
//

#import <UIKit/UIKit.h>
#import "../Configurable.h"
#import "../Tracer.h"

#import <vector>

namespace bugsnag {
class ViewLoadInstrumentation {
public:
    ViewLoadInstrumentation(std::shared_ptr<Tracer> tracer, std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
    : isEnabled_(false)
    , tracer_(tracer)
    , spanAttributesProvider_(spanAttributesProvider)
    {}

    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void start() noexcept;
    
private:
    static std::vector<const char *> imagesToInstrument() noexcept;
    static std::vector<Class> viewControllerSubclasses(const char *image) noexcept;
    static bool isViewControllerSubclass(Class subclass) noexcept;
    
    void instrument(Class cls) noexcept;
    
    void onLoadView(UIViewController *viewController) noexcept;
    void onViewDidAppear(UIViewController *viewController) noexcept;
    void onViewWillDisappear(UIViewController *viewController) noexcept;

    void endViewLoadSpan(UIViewController *viewController) noexcept;

    bool isEnabled_{false};
    std::shared_ptr<Tracer> tracer_;
    BOOL (^ callback_)(UIViewController *viewController){nullptr};
    NSSet *observedClasses_{nil};
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
};
}
