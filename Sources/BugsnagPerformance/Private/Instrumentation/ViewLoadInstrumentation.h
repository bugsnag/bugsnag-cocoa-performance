//
//  ViewLoadInstrumentation.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 10/10/2022.
//

#import <UIKit/UIKit.h>

#import <vector>

namespace bugsnag {
class ViewLoadInstrumentation {
public:
    ViewLoadInstrumentation(class Tracer &tracer, BOOL (^ callback)(UIViewController *)) noexcept
    : tracer_(tracer)
    , callback_(callback)
    {}
    
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

    class Tracer &tracer_;
    BOOL (^ callback_)(UIViewController *viewController){nullptr};
    NSSet *observedClasses_{nil};
};
}
