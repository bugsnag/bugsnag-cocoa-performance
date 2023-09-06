//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Foundation/Foundation.h>
#include <mach/mach_time.h>
#include <mach/mach_error.h>

/**
 * Get difference between two calls of mach_absolute_time()
 */
static inline double ksmachtimeDifferenceInSeconds(const uint64_t endTime,
                                         const uint64_t startTime) {
    // From
    // http://lists.apple.com/archives/perfoptimization-dev/2005/Jan/msg00039.html

    static double conversion = 0;

    if (conversion == 0) {
        mach_timebase_info_data_t info = {0};
        kern_return_t kr = mach_timebase_info(&info);
        if (kr != KERN_SUCCESS) {
            NSLog(@"Error: mach_timebase_info: %s", mach_error_string(kr));
            return 0;
        }

        conversion = 1e-9 * (double)info.numer / (double)info.denom;
    }

    return conversion * (double)(endTime - startTime);
}

static inline uint64_t begin_timed_op() {
    return mach_absolute_time();
}

static inline void end_timed_op(NSString *name, uint64_t startTime) {
    uint64_t endTime = mach_absolute_time();
    NSLog(@"### TIMED %@: %fs", name, ksmachtimeDifferenceInSeconds(endTime, startTime));
}
