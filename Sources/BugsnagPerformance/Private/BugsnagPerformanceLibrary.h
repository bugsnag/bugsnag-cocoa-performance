//
//  BugsnagPerformanceLibrary.h
//  
//
//  Created by Karl Stenerud on 11.04.23.
//

#pragma once

#import "BugsnagPerformanceImpl.h"
#import "Instrumentation/AppStartupInstrumentation.h"

namespace bugsnag {

/**
 * This singleton instance class ensures the correct initialization order and configuration of all library components.
 */
class BugsnagPerformanceLibrary {
public:
    static void configure(BugsnagPerformanceConfiguration *config) noexcept;

    static std::shared_ptr<BugsnagPerformanceImpl> getBugsnagPerformanceImpl() noexcept;
    static std::shared_ptr<AppStartupInstrumentation> getAppStartupInstrumentation() noexcept;

private:
    // Use GNU constructor attribute to auto-call functions before main() is called.
    // https://gcc.gnu.org/onlinedocs/gcc-4.7.0/gcc/Function-Attributes.html
    // Priority is 101-65535, with higher values running later.

    // Automatically called as early as possible.
    static void calledAsEarlyAsPossible() noexcept __attribute__((constructor(101)));

    // Automatically called right before main() is called.
    static void calledRightBeforeMain() noexcept __attribute__((constructor(65535)));

    void configureInstance(BugsnagPerformanceConfiguration *config) noexcept;

    BugsnagPerformanceLibrary();
    std::shared_ptr<BugsnagPerformanceImpl> bugsnagPerformanceImpl_;
    std::shared_ptr<AppStartupInstrumentation> appStartupInstrumentation_;
};

}
