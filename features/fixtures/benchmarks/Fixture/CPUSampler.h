//
//  CPUSampler.h
//  Fixture
//
//  Created by Robert Bartoszewski on 09/09/2025.
//

#import <Foundation/Foundation.h>

@interface CPUSample: NSObject

@property (nonatomic, readonly) CFAbsoluteTime sampledAt;
@property (nonatomic, readonly) NSTimeInterval cpuTime;

- (double)usageSince:(CPUSample *)other;

@end

@interface CPUSampler: NSObject

- (CPUSample *)recordSample;

@end
