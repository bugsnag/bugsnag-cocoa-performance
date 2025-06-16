//
//  BugsnagPerformanceSpanQuery.m
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanQuery.h>

@interface BugsnagPerformanceSpanQuery ()

@property (nonatomic, copy, nullable) Class resultType_;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *attributes;

@end

@implementation BugsnagPerformanceSpanQuery

+ (instancetype)queryWithResultType:(Class)resultType {
    return [self queryWithResultType:resultType attributes:[NSDictionary dictionary]];
}

+ (instancetype)queryWithResultType:(Class)resultType attributes:(NSDictionary<NSString *,id> *)attributes {
    return [[self alloc] initWithResultType:resultType attributes:attributes];
}

- (instancetype)initWithResultType:(Class)resultType attributes:(NSDictionary<NSString *, id> *)attributes {
    self = [super init];
    if (self) {
        _resultType_ = resultType;
        _attributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
    }
    return self;
}

- (Class)resultType {
    return self.resultType_;
}

- (id)getAttributeWithName:(NSString *)name {
    return self.attributes[name];
}

@end

@implementation BugsnagPerformanceMutableSpanQuery

- (void)setAttributeWithName:(NSString *)name value:(id)value {
    self.attributes[name] = value;
}

- (void)setResultType:(nonnull Class)type {
    self.resultType_ = type;
}

@end
