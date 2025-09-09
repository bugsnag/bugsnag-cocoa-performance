//
//  CPUSampler.mm
//  Fixture
//
//  Created by Robert Bartoszewski on 09/09/2025.
//

#import "CPUSampler.h"

#import <sys/utsname.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

static inline NSTimeInterval timeValToTimeInterval(time_value_t value) {
    return (NSTimeInterval)value.seconds + ((NSTimeInterval)value.microseconds / TIME_MICROS_MAX);
}

NSTimeInterval taskTime() {
    mach_port_t thread = 0;
    thread_basic_info_data_t threadBasicInfo;
    mach_msg_type_number_t count = THREAD_BASIC_INFO_COUNT;
    auto status = thread_info(thread, THREAD_BASIC_INFO, (thread_info_t)&threadBasicInfo, &count);
    if (status != KERN_SUCCESS) {
        return -1;
    }
    return timeValToTimeInterval(threadBasicInfo.user_time);
}

static double calcCPUUsagePct(CFAbsoluteTime earlierSampledAtTime,
                              NSTimeInterval earlierTimeValue,
                              CFAbsoluteTime currentSampledAtTime,
                              NSTimeInterval currentTimeValue) {
    auto diffClockSec = currentSampledAtTime - earlierSampledAtTime;
    if (diffClockSec <= 0) {
        return 0;
    }
    auto diffCPUTimeSec = currentTimeValue - earlierTimeValue;
    auto result = diffCPUTimeSec / diffClockSec * 100;
    return result;
}


@interface CPUSample ()
@property (nonatomic) CFAbsoluteTime sampledAt;
@property (nonatomic) NSTimeInterval cpuTime;
@end

@implementation CPUSample

- (double)usageSince:(CPUSample *)other {
    return calcCPUUsagePct(other.sampledAt, other.cpuTime, self.sampledAt, self.cpuTime);
}

@end

@implementation CPUSampler

- (CPUSample *)recordSample {
    CFAbsoluteTime sampledAt = CFAbsoluteTimeGetCurrent();
    NSTimeInterval cpuTime = taskTime();
    if (cpuTime < 0) {
        return nil;
    }
    CPUSample *sample = [CPUSample new];
    sample.sampledAt = sampledAt;
    sample.cpuTime = cpuTime;
    return sample;
}

@end
