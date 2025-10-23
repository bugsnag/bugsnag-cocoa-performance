//
//  AsyncToSyncTask.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncToSyncTask.h"

const NSTimeInterval maxWaitInterval = 20.0;

using namespace bugsnag;

bool
AsyncToSyncTask::executeSync() {
    __block auto blockThis = this;
    __block BOOL result = NO;
    __block BOOL didComplete = NO;
    __block BOOL isWaiting = NO;
    __block auto condition = [NSCondition new];

    mutex_.lock();
    [condition lock];
    work_(^(bool workResult){
        result = workResult;
        didComplete = YES;
        blockThis->mutex_.lock();
        if (isWaiting) {
            [condition lock];
            [condition signal];
            [condition unlock];
        }
        blockThis->mutex_.unlock();
    });
    
    isWaiting = YES;
    mutex_.unlock();
    
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:maxWaitInterval];
    while (timeoutDate.timeIntervalSinceNow > 0 && !didComplete) {
        [condition waitUntilDate:timeoutDate];
    }
    [condition unlock];
    
    return result;
}
