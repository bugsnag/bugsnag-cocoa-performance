//
//  BSGPSystemInfo.mm
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 08.01.25.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "BSGPSystemInfo.h"
#import <sys/utsname.h>
#import "Utils.h"

using namespace bugsnag;

struct kinfo_proc *BSGPSystemInfo::kinfoProc() {
    size_t len = 4;
    int mib[len];
    sysctlnametomib("kern.proc.pid", mib, &len);
    mib[3] = getpid();
    len = sizeof(data_.kinfoProc);
    sysctl(mib, 4, &data_.kinfoProc, &len, NULL, 0);
    return &data_.kinfoProc;
}

task_thread_times_info_data_t *BSGPSystemInfo::taskTimeInfo() {
    mach_msg_type_number_t count = TASK_THREAD_TIMES_INFO_COUNT;
    auto status = task_info(mach_task_self(), TASK_THREAD_TIMES_INFO, (task_info_t)&data_.taskThreadTimesInfo, &count);
    if (status != KERN_SUCCESS) {
        BSGLogDebug(@"task_info(TASK_THREAD_TIMES_INFO) failed. Status = %d", status);
        return nullptr;
    }
    return &data_.taskThreadTimesInfo;
}

task_vm_info_data_t *BSGPSystemInfo::taskVMInfo() {
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    auto status = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&data_.taskVMInfo, &count);
    if (status != KERN_SUCCESS) {
        BSGLogDebug(@"task_info(TASK_VM_INFO) failed. Status = %d", status);
        return nullptr;
    }
    return &data_.taskVMInfo;
}

task_power_info_v2_data_t *BSGPSystemInfo::taskPowerInfoV2() {
    mach_msg_type_number_t count = TASK_POWER_INFO_V2_COUNT;
    auto status = task_info(mach_task_self(), TASK_POWER_INFO_V2, (task_info_t)&data_.taskPowerInfoV2, &count);
    if (status != KERN_SUCCESS) {
        BSGLogDebug(@"task_info(TASK_POWER_INFO_V2) failed. Status = %d", status);
        return nullptr;
    }
    return &data_.taskPowerInfoV2;
}

thread_basic_info_data_t *BSGPSystemInfo::threadBasicInfo(mach_port_t thread) {
    mach_msg_type_number_t count = THREAD_BASIC_INFO_COUNT;
    auto status = thread_info(thread, THREAD_BASIC_INFO, (thread_info_t)&data_.threadBasicInfo, &count);
    if (status != KERN_SUCCESS) {
        BSGLogDebug(@"thread_info(THREAD_BASIC_INFO) on thread %d failed. Status = %d", thread, status);
        return nullptr;
    }
    return &data_.threadBasicInfo;
}

processor_info_array_t BSGPSystemInfo::cpuLoadInfo(int *elementCount) {
    deallocCPUInfo();
    natural_t cpuCount = 0;
    auto status = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &cpuInfo_, &cpuInfoCount_);
    if(status != KERN_SUCCESS) {
        BSGLogDebug(@"host_processor_info(PROCESSOR_CPU_LOAD_INFO) failed. Status = %d", status);
        cpuInfo_ = nullptr;
        cpuInfoCount_ = 0;
    }
    *elementCount = (int)cpuInfoCount_;
    return cpuInfo_;
}

thread_act_array_t BSGPSystemInfo::allThreads(int *elementCount) {
    deallocAllThreads();
    auto status = task_threads(mach_task_self(), &allThreads_, &allThreadsCount_);
    if (status != KERN_SUCCESS) {
        BSGLogDebug(@"task_threads() failed. Status = %d", status);
        deallocAllThreads();
    }
    *elementCount = (int)allThreadsCount_;
    return allThreads_;
}

void BSGPSystemInfo::deallocAllThreads() {
    if (allThreads_ != nullptr) {
        vm_deallocate(mach_task_self(), (vm_address_t)allThreads_, sizeof(allThreads_[0]) * allThreadsCount_);
        allThreadsCount_ = 0;
        allThreads_ = nullptr;
    }
}

void BSGPSystemInfo::deallocCPUInfo() {
    if (cpuInfo_ != nullptr) {
        vm_deallocate(mach_task_self(), (vm_address_t)cpuInfo_, sizeof(cpuInfo_[0]) * cpuInfoCount_);
        cpuInfo_ = nullptr;
        cpuInfoCount_ = 0;
    }
}

NSString *BSGPSystemInfo::deviceModel() {
    if (deviceModel_ == nil) {
        struct utsname systemInfo;
        uname(&systemInfo);
        deviceModel_ = [NSString stringWithUTF8String:systemInfo.machine];
    }
    return deviceModel_;
}

float BSGPSystemInfo::batteryLevel() {
    UIDevice *dev = UIDevice.currentDevice;
    dev.batteryMonitoringEnabled = YES;
    return dev.batteryLevel;
}

UIDeviceBatteryState BSGPSystemInfo::batteryState() {
    UIDevice *dev = UIDevice.currentDevice;
    dev.batteryMonitoringEnabled = YES;
    return dev.batteryState;
}

unsigned long long BSGPSystemInfo::physicalMemoryBytes() {
    return NSProcessInfo.processInfo.physicalMemory;
}

NSUInteger BSGPSystemInfo::activeProcessorCount() {
    return NSProcessInfo.processInfo.activeProcessorCount;
}

double BSGPSystemInfo::calcCPUUsagePct(CFAbsoluteTime lastSampledAtSec,
                                       uint64_t *lastTimeValueUSInOut,
                                       CFAbsoluteTime nowSampledAtSec,
                                       time_value_t nowTimeValue) {
    uint64_t lastTimeValueUS = *lastTimeValueUSInOut;
    uint64_t nowTimeValueUS = (uint64_t)(nowTimeValue.seconds * TIME_MICROS_MAX + nowTimeValue.microseconds);
    *lastTimeValueUSInOut = nowTimeValueUS;

    double diffCPUTimeSec = (double)(nowTimeValueUS - lastTimeValueUS) / TIME_MICROS_MAX;
    CFAbsoluteTime diffClockSec = nowSampledAtSec - lastSampledAtSec;
    return (double)diffCPUTimeSec / diffClockSec * 100;
}
