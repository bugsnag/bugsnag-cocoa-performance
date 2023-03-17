//
//  PersistentState.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

namespace bugsnag {

class PersistentState {
public:
    PersistentState(NSString *jsonFilePath, void (^onPersistenceNeeded)()) noexcept;
    PersistentState() = delete;

    void setProbability(double probability) noexcept;
    double probability(void) noexcept {return probability_;};

    /**
     * Save this object to persistent storage.
     * This method should only be called from the worker thread.
     */
    NSError *persist() noexcept;

    /**
     * Load this object from persistent storage.
     * This method should only be called once at startup.
     */
    NSError *load() noexcept;
private:
    NSString *jsonFilePath_{nil};
    NSString *persistentStateDir_{nil};
    double probability_{0};
    void (^onPersistenceNeeded_)(){nil};
};

}
