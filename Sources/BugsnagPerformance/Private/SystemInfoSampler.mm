//
//  SystemInfoSampler.mm
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.01.25.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "SystemInfoSampler.h"
#import <algorithm>
#import "Utils.h"

using namespace bugsnag;

static inline NSTimeInterval timeValToTimeInterval(time_value_t value) {
    return (NSTimeInterval)value.seconds + ((NSTimeInterval)value.microseconds / TIME_MICROS_MAX);
}

CFAbsoluteTime SystemInfoSampler::calculateAppStartTime() {
    auto kinfoProc = systemInfo_.kinfoProc();
    struct timeval startTime = kinfoProc->kp_proc.p_un.__p_starttime;
    struct timeval nowTime;
    gettimeofday(&nowTime, NULL);

    int64_t diff = ((int64_t)nowTime.tv_sec * (int64_t)USEC_PER_SEC) + (int64_t)nowTime.tv_usec;
    diff -= ((int64_t)startTime.tv_sec * (int64_t)USEC_PER_SEC) + (int64_t)startTime.tv_usec;

    return CFAbsoluteTimeGetCurrent() - (double)diff / USEC_PER_SEC;
}

void SystemInfoSampler::earlyConfigure(BSGEarlyConfiguration *) noexcept {
    // Get our first sample as early as possible.
    // This sample will be relative to the app start.
    lastSampledAtTime_ = calculateAppStartTime();
    recordSample();
}

void SystemInfoSampler::earlySetup() noexcept {
    // Assume for now that the user wants to record samples.
    mainThread_ = mach_thread_self();
    samplerThread_ = [[NSThread alloc] initWithBlock:^{

        for (;;) {
            [NSThread sleepForTimeInterval:samplePeriod_];
            if (shouldAbortSamplerThread_) {
                // It turns out that the user didn't want to record samples.
                break;
            }
            recordSample();
        }

        // We've aborted because config.enabledMetrics.cpu was false.
        // Clear everything and leave this thread.
        samples_.clear();
    }];

    [samplerThread_ start];
}

void SystemInfoSampler::configure(BugsnagPerformanceConfiguration *config) noexcept {
    shouldSampleCPU_ = config.enabledMetrics.cpu;
    if (!shouldSampleCPU_) {
        shouldAbortSamplerThread_ = true;
    }
}

static double calcCPUUsagePct(CFAbsoluteTime earlierSampledAtTime,
                              time_value_t earlierTimeValue,
                              CFAbsoluteTime currentSampledAtTime,
                              time_value_t currentTimeValue) {
    auto diffClockSec = currentSampledAtTime - earlierSampledAtTime;
    if (diffClockSec <= 0) {
        BSGLogDebug(@"calcCPUUsagePct(): Clock %f - %f = %f, so returning 0", currentSampledAtTime, earlierSampledAtTime, diffClockSec);
        return 0;
    }
    auto diffCPUTimeSec = timeValToTimeInterval(currentTimeValue) - timeValToTimeInterval(earlierTimeValue);
    BSGLogTrace(@"calcCPUUsagePct(): CPU %f - %f = %f, so returning %f / %f * 100 = %f",
                timeValToTimeInterval(currentTimeValue), timeValToTimeInterval(earlierTimeValue), diffCPUTimeSec,
                diffCPUTimeSec, diffClockSec, diffCPUTimeSec / diffClockSec * 100);
    return diffCPUTimeSec / diffClockSec * 100;
}

void SystemInfoSampler::recordSample() {
    SystemInfoSampleData sample(CFAbsoluteTimeGetCurrent());

    if (shouldSampleCPU_) {
        auto taskInfo = systemInfo_.taskTimeInfo();
        if (taskInfo != nullptr) {
            sample.processCPUPct = calcCPUUsagePct(lastSampledAtTime_,
                                                   lastSampleProcessCPU_,
                                                   sample.sampledAt,
                                                   taskInfo->user_time);
            lastSampleProcessCPU_ = taskInfo->user_time;
            BSGLogTrace(@"taskInfo: %d.%d = %f", taskInfo->user_time.seconds, taskInfo->user_time.microseconds, sample.processCPUPct);
        }

        auto mainThreadInfo = systemInfo_.threadBasicInfo(mainThread_);
        if (mainThreadInfo != nullptr) {
            sample.mainThreadCPUPct = calcCPUUsagePct(lastSampledAtTime_,
                                                      lastSampleMainThreadCPU_,
                                                      sample.sampledAt,
                                                      mainThreadInfo->user_time);
            lastSampleMainThreadCPU_ = mainThreadInfo->user_time;
            BSGLogTrace(@"mainThreadInfo: %d.%d = %f", mainThreadInfo->user_time.seconds, mainThreadInfo->user_time.microseconds, sample.mainThreadCPUPct);
        }

        // First call to captureSample() will be from the main thread because the monitor thread
        // won't exist yet
        auto thread_self = mach_thread_self();
        if (thread_self != mainThread_) {
            auto monitorThreadInfo = systemInfo_.threadBasicInfo(thread_self);
            if (monitorThreadInfo != nullptr) {
                sample.monitorThreadCPUPct = calcCPUUsagePct(lastSampledAtTime_,
                                                             lastSampleMonitorThreadCPU_,
                                                             sample.sampledAt,
                                                             monitorThreadInfo->user_time);
                lastSampleMonitorThreadCPU_ = monitorThreadInfo->user_time;
                BSGLogTrace(@"monitorThreadInfo: %d.%d = %f", monitorThreadInfo->user_time.seconds, monitorThreadInfo->user_time.microseconds, sample.monitorThreadCPUPct);
            }
        }
    }

    lastSampledAtTime_ = sample.sampledAt;

    if (sample.hasValidData()) {
//        std::lock_guard<std::mutex> guard(mutex_);
        samples_.push_back(sample);
    }
}

std::vector<SystemInfoSampleData> SystemInfoSampler::samplesAroundTimePeriod(CFAbsoluteTime startTime, CFAbsoluteTime endTime) {
//    std::lock_guard<std::mutex> guard(mutex_);
    if (samples_.empty()) {
        BSGLogTrace(@"SystemInfoSampler::samplesAroundTimePeriod(): No samples available");
        return std::vector<SystemInfoSampleData>();
    }

    auto lower = std::lower_bound(samples_.begin(), samples_.end(), startTime, SystemInfoSampleData::CompareSampledAtLower);
    auto upper = std::upper_bound(samples_.begin(), samples_.end(), endTime, SystemInfoSampleData::CompareSampledAtUpper);

    auto lowerMinus1 = lower == samples_.begin() || lower == samples_.end() ? samples_.begin() : lower - 1;
    auto upperPlus1 = upper == samples_.end() ? samples_.end() : upper + 1;

    std::vector<SystemInfoSampleData> result;
    result.insert(result.begin(), lowerMinus1, upperPlus1);
    BSGLogTrace(@"SystemInfoSampler::samplesAroundTimePeriod(): Found %zu samples around times %f and %f", result.size(), startTime, endTime);
    return result;
}
