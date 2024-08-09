//
//  PersistentState.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "PersistentState.h"
#import "JSON.h"
#import "Filesystem.h"
#import "BugsnagPerformanceConfiguration+Private.h"

using namespace bugsnag;

static NSNumber *getNumber(NSDictionary* dict, NSString *key) {
    NSNumber *value = dict[key];
    return [value isKindOfClass:[NSNumber class]] ? value : nil;
}

void PersistentState::setProbability(double probability) noexcept {
    if (probability != probability_) {
        probability_ = probability;
        persist();
    }
}

NSError *PersistentState::persist() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    NSError *error = [Filesystem ensurePathExists:persistentStateDir_];
    if (error != nil) {
        return error;
    }

    return JSON::dictionaryToFile(jsonFilePath_, @{
        @"probability": @(probability_)
    });
}

void PersistentState::configure(BugsnagPerformanceConfiguration *config) noexcept {
    probability_ = config.internal.initialSamplingProbability;
};

void PersistentState::preStartSetup() noexcept {
    persistentStateDir_ = persistence_->bugsnagPerformanceDir();
    jsonFilePath_ = [persistentStateDir_ stringByAppendingPathComponent:@"persistent-state.json"];

    NSError *error = nil;
    NSDictionary *dict = JSON::fileToDictionary(jsonFilePath_, &error);
    if (dict == nil) {
        persist();
        return;
    }

    NSNumber *probability = getNumber(dict, @"probability");
    if (probability != nil) {
        probability_ = probability.doubleValue;
    }
}

