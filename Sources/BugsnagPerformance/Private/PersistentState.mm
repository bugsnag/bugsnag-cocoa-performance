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

using namespace bugsnag;

static NSNumber *getNumber(NSDictionary* dict, NSString *key) {
    NSNumber *value = dict[key];
    return [value isKindOfClass:[NSNumber class]] ? value : nil;
}

void PersistentState::setProbability(double probability) noexcept {
    probability_ = probability;
    onPersistenceNeeded_();
}

NSError *PersistentState::persist() noexcept {
    NSError *error = [Filesystem ensurePathExists:persistentStateDir_];
    if (error != nil) {
        return error;
    }

    return JSON::dictionaryToFile(jsonFilePath_, @{
        @"probability": @(probability_)
    });
}

NSError *PersistentState::load() noexcept {
    NSError *error = nil;
    NSDictionary *dict = JSON::fileToDictionary(jsonFilePath_, &error);
    if (dict == nil) {
        return error;
    }

    NSNumber *probability = getNumber(dict, @"probability");
    if (probability != nil) {
        probability_ = probability.doubleValue;
        probabilityIsValid_= true;
    }

    return nil;
}

