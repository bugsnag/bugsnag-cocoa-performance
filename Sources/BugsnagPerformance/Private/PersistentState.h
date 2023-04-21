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
    PersistentState() = delete;
    PersistentState(NSString *jsonFilePath, void (^onPersistenceNeeded)()) noexcept
    : jsonFilePath_(jsonFilePath)
    , persistentStateDir_([jsonFilePath_ stringByDeletingLastPathComponent])
    , probability_(0)
    , probabilityIsValid_(false)
    , onPersistenceNeeded_(onPersistenceNeeded)
    {}

    void setProbability(double probability) noexcept;
    double probability(void) noexcept {return probability_;};
    bool probabilityIsValid() noexcept {return probabilityIsValid_;}

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
    bool probabilityIsValid_{false};
    void (^onPersistenceNeeded_)(){nil};
};

}
