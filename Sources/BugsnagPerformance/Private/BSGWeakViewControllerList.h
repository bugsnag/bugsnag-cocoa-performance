//
//  BSGWeakViewControllerList.h
//  BugsnagPerformance
//
//  Created by Robert B on 13/02/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <mutex>

@interface BSGWeakViewControllerPointer: NSObject

// We use a weak wrapper because NSPointerArray.weakObjectsPointerArray's compact method is broken.
@property(nonatomic,readonly,weak) UIViewController *viewController;

+ (instancetype)pointerWithViewController:(UIViewController *)viewController;

@end

namespace bugsnag {

class BSGWeakViewControllerList {
public:
    BSGWeakViewControllerList()
    : viewControllers_([NSMutableArray new])
    {}

    void add(UIViewController *viewController) noexcept {
        auto ptr = [BSGWeakViewControllerPointer pointerWithViewController:viewController];
        std::lock_guard<std::mutex> guard(mutex_);
        [viewControllers_ addObject:ptr];
    }
    
    void remove(UIViewController *viewController) noexcept {
        std::lock_guard<std::mutex> guard(mutex_);
        auto newViewControllers = [NSMutableArray arrayWithCapacity:viewControllers_.count];
        for (BSGWeakViewControllerPointer *ptr in viewControllers_) {
            if (viewController != ptr.viewController) {
                [newViewControllers addObject:ptr];
            }
        }
        viewControllers_ = newViewControllers;
    }

    void compact() noexcept {
        std::lock_guard<std::mutex> guard(mutex_);
        bool canCompact = false;
        for (BSGWeakViewControllerPointer *ptr in viewControllers_) {
            UIViewController *viewController = ptr.viewController;
            if (viewController == nil) {
                canCompact = true;
                break;
            }
        }
        if (canCompact) {
            auto newViewControllers = [NSMutableArray arrayWithCapacity:viewControllers_.count];
            for (BSGWeakViewControllerPointer *ptr in viewControllers_) {
                UIViewController *viewController = ptr.viewController;
                if (viewController != nil) {
                    [newViewControllers addObject:ptr];
                }
            }
            viewControllers_ = newViewControllers;
        }
    }
    
    void forEach(void (^block)(UIViewController *)) {
        for (BSGWeakViewControllerPointer *pointer in viewControllers_) {
            auto viewController = pointer.viewController;
            if (viewController != nil) {
                block(viewController);
            }
        }
    }

    NSUInteger count() noexcept {
        std::lock_guard<std::mutex> guard(mutex_);
        return viewControllers_.count;
    }

private:
    std::mutex mutex_;
    NSMutableArray<BSGWeakViewControllerPointer *> *viewControllers_;
};

}
