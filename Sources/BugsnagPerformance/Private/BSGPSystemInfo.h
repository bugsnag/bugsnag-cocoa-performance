//
//  BSGPSystemInfo.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 08.01.25.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <sys/sysctl.h>
#import <mutex>
#import "FixedLengthDequeue.h"

// https://web.mit.edu/darwin/src/modules/xnu/osfmk/man/

namespace bugsnag {

typedef struct {
    task_vm_info_data_t taskVMInfo;
    mach_task_basic_info_data_t taskBasicInfo;
    task_power_info_data_t taskPowerInfo;
    task_power_info_v2_data_t taskPowerInfoV2;
    thread_basic_info_data_t threadBasicInfo;
    thread_extended_info_data_t threadExtendedInfo;
    task_thread_times_info_data_t taskThreadTimesInfo;
    struct kinfo_proc kinfoProc;
} BSGPSystemData;

/**
 * Interface to get information about the running system.
 * Any calls that would require local storage will be stored locally in this object.
 *
 * WARNING:
 * Methods that return a pointer to a xyz_data_t will point to data stored locally on this object (see BSGPSystemData).
 * Therefore, calling the same method again on the same instance will OVERWRITE the pointed-to data!
 * Save any pointed-to data before calling another method on the same BSGPSystemInfo instance.
 *
 * Needless to say, THIS CLASS IS NOT THREAD SAFE.
 */
class BSGPSystemInfo {
public:
    static constexpr size_t cpuHistogramSize{30};
public:
    BSGPSystemInfo();

    /**
     * Get the number of CPUs that are allocated to this process.
     */
    NSUInteger activeProcessorCount();

    /**
     * Get this device's unique model ID (for example, "iPhone12,8")
     */
    NSString *deviceModel();

    struct kinfo_proc *kinfoProc();

    // struct task_thread_times_info {
    //     time_value_t    user_time;      /* total user run time for live threads */
    //     time_value_t    system_time;    /* total system run time for live threads */ - Disabled on iOS
    // };
    task_thread_times_info_data_t *taskTimeInfo();

    // struct task_vm_info {
    //     mach_vm_size_t  virtual_size;       /* virtual memory size (bytes) */
    //     integer_t       region_count;       /* number of memory regions */
    //     integer_t       page_size;
    //     mach_vm_size_t  resident_size;      /* resident memory size (bytes) */
    //     mach_vm_size_t  resident_size_peak; /* peak resident size (bytes) */
    //
    //     mach_vm_size_t  device; - Disabled on iOS
    //     mach_vm_size_t  device_peak; - Disabled on iOS
    //     mach_vm_size_t  internal;
    //     mach_vm_size_t  internal_peak;
    //     mach_vm_size_t  external;
    //     mach_vm_size_t  external_peak; - Disabled on iOS
    //     mach_vm_size_t  reusable;
    //     mach_vm_size_t  reusable_peak; - Disabled on iOS
    //     mach_vm_size_t  purgeable_volatile_pmap; - Disabled on iOS
    //     mach_vm_size_t  purgeable_volatile_resident; - Disabled on iOS
    //     mach_vm_size_t  purgeable_volatile_virtual; - Disabled on iOS
    //     mach_vm_size_t  compressed; - Disabled on iOS
    //     mach_vm_size_t  compressed_peak; - Disabled on iOS
    //     mach_vm_size_t  compressed_lifetime; - Disabled on iOS
    //
    //     /* added for rev1 */
    //     mach_vm_size_t  phys_footprint;
    //
    //     /* added for rev2 */
    //     mach_vm_address_t       min_address;
    //     mach_vm_address_t       max_address;
    //
    //     /* added for rev3 */
    //     int64_t ledger_phys_footprint_peak;
    //     int64_t ledger_purgeable_nonvolatile;
    //     int64_t ledger_purgeable_novolatile_compressed; - Disabled on iOS
    //     int64_t ledger_purgeable_volatile; - Disabled on iOS
    //     int64_t ledger_purgeable_volatile_compressed; - Disabled on iOS
    //     int64_t ledger_tag_network_nonvolatile; - Disabled on iOS
    //     int64_t ledger_tag_network_nonvolatile_compressed; - Disabled on iOS
    //     int64_t ledger_tag_network_volatile; - Disabled on iOS
    //     int64_t ledger_tag_network_volatile_compressed; - Disabled on iOS
    //     int64_t ledger_tag_media_footprint; - Disabled on iOS
    //     int64_t ledger_tag_media_footprint_compressed; - Disabled on iOS
    //     int64_t ledger_tag_media_nofootprint; - Disabled on iOS
    //     int64_t ledger_tag_media_nofootprint_compressed; - Disabled on iOS
    //     int64_t ledger_tag_graphics_footprint; - Disabled on iOS
    //     int64_t ledger_tag_graphics_footprint_compressed; - Disabled on iOS
    //     int64_t ledger_tag_graphics_nofootprint; - Disabled on iOS
    //     int64_t ledger_tag_graphics_nofootprint_compressed; - Disabled on iOS
    //     int64_t ledger_tag_neural_footprint; - Disabled on iOS
    //     int64_t ledger_tag_neural_footprint_compressed; - Disabled on iOS
    //     int64_t ledger_tag_neural_nofootprint; - Disabled on iOS
    //     int64_t ledger_tag_neural_nofootprint_compressed; - Disabled on iOS
    //
    //     /* added for rev4 */
    //     uint64_t limit_bytes_remaining;
    //
    //     /* added for rev5 */
    //     integer_t decompressions; - Disabled on iOS
    //
    //     /* added for rev6 */
    //     int64_t ledger_swapins; - Disabled on iOS
    // };
    task_vm_info_data_t *taskVMInfo();

    // struct task_power_info {
    //     uint64_t                total_user;
    //     uint64_t                total_system; - Disabled on iOS
    //     uint64_t                task_interrupt_wakeups;
    //     uint64_t                task_platform_idle_wakeups;
    //     uint64_t                task_timer_wakeups_bin_1;
    //     uint64_t                task_timer_wakeups_bin_2;
    // };
    //
    // typedef struct {
    //     uint64_t                task_gpu_utilisation; - Disabled on iOS
    //     uint64_t                task_gpu_stat_reserved0;
    //     uint64_t                task_gpu_stat_reserved1;
    //     uint64_t                task_gpu_stat_reserved2;
    // } gpu_energy_data;
    //
    // struct task_power_info_v2 {
    //     task_power_info_data_t  cpu_energy;
    //     gpu_energy_data gpu_energy;
    // #if defined(__arm__) || defined(__arm64__)
    //     uint64_t                task_energy; // in nanojoules
    // #endif /* defined(__arm__) || defined(__arm64__) */
    //     uint64_t                task_ptime;
    //     uint64_t                task_pset_switches;
    // };
    task_power_info_v2_data_t *taskPowerInfoV2();

    // struct thread_basic_info {
    //     time_value_t    user_time;      /* user run time */
    //     time_value_t    system_time;    /* system run time */ - Disabled on iOS
    //     integer_t       cpu_usage;      /* scaled cpu usage percentage */ - Disabled on iOS?
    //     policy_t        policy;         /* scheduling policy in effect */
    //     integer_t       run_state;      /* run state (see below) */
    //     integer_t       flags;          /* various flags (see below) */
    //     integer_t       suspend_count;  /* suspend count for thread */
    //     integer_t       sleep_time;     /* number of seconds that thread has been sleeping */
    // };
    thread_basic_info_data_t *threadBasicInfo(mach_port_t thread);

    // Returned array contains 4 elements per CPU:
    //     #define CPU_STATE_USER          0
    //     #define CPU_STATE_SYSTEM        1
    //     #define CPU_STATE_IDLE          2
    //     #define CPU_STATE_NICE          3
    //
    // Only USER and IDLE are populated on iOS.
    processor_info_array_t cpuLoadInfo(int *out_elementCount);

    // Returned array contains one thread ID per element.
    thread_act_array_t allThreads(int *out_elementCount);

    // UIDeviceBatteryStateUnknown,
    // UIDeviceBatteryStateUnplugged,   // on battery, discharging
    // UIDeviceBatteryStateCharging,    // plugged in, less than 100%
    // UIDeviceBatteryStateFull,        // plugged in, at 100%
    UIDeviceBatteryState batteryState();

    // 0 .. 1.0. -1.0 if UIDeviceBatteryStateUnknown
    float batteryLevel();

    uint64_t physicalMemoryBytesTotal() { return physicalMemoryBytesTotal_; }

private:
    void deallocAllThreads();
    void deallocCPUInfo();

private:
    BSGPSystemData data_; // Don't need to initialize
    processor_info_array_t cpuInfo_{0};
    mach_msg_type_number_t cpuInfoCount_{0};
    thread_act_array_t allThreads_{0};
    mach_msg_type_number_t allThreadsCount_{0};
    NSString *deviceModel_{nil};
    uint64_t lastProcessCPUTimeUS_{0};
    CFAbsoluteTime lastProcessCPUSampledAtSec_{0};
    uint64_t lastThisThreadCPUTimeUS_{0};
    CFAbsoluteTime lastThisThreadCPUSampledAtSec_{0};
    CFAbsoluteTime lastCPUSampledAtSec_{0};
    uint64_t physicalMemoryBytesTotal_;

public:
    ~BSGPSystemInfo() {
        deallocAllThreads();
    }
};

}

