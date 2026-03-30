#import "RetryQueueWrapper.h"

@interface ObjCRetryQueue : NSObject
@property (nonatomic, strong) NSString *baseDir;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *queue;
@property (nonatomic, copy) dispatch_block_t onFilesystemError;
- (instancetype)initWithPath:(NSString *)path;
- (void)preStartSetup;
- (void)sweep;
- (NSArray<NSNumber *> *)list;
- (NSDictionary *)get:(uint64_t)timestamp;
- (void)remove:(uint64_t)timestamp;
- (void)setOnFilesystemError:(dispatch_block_t)block;
- (void)disableFilesystemIO;
@end

@implementation ObjCRetryQueue
- (instancetype)initWithPath:(NSString *)path {
    if ((self = [super init])) {
        _baseDir = path;
        _queue = [NSMutableArray array];
    }
    return self;
}
- (void)preStartSetup {}
- (void)sweep {
    // Remove items older than 24 hours (simulate)
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *obj, NSDictionary *bindings) {
        NSNumber *ts = obj[@"timestamp"];
        return ts && ([ts doubleValue] > now - 24*60*60);
    }];
    [_queue filterUsingPredicate:predicate];
}
- (NSArray<NSNumber *> *)list {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:_queue.count];
    for (NSDictionary *item in _queue) {
        [result addObject:item[@"timestamp"]];
    }
    return [result copy];
}
- (NSDictionary *)get:(uint64_t)timestamp {
    for (NSDictionary *item in _queue) {
        if ([item[@"timestamp"] unsignedLongLongValue] == timestamp) {
            return item;
        }
    }
    return nil;
}

- (void)remove:(uint64_t)timestamp {
    NSIndexSet *indexes = [_queue indexesOfObjectsPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        return [item[@"timestamp"] unsignedLongLongValue] == timestamp;
    }];
    [_queue removeObjectsAtIndexes:indexes];
}

- (void)setOnFilesystemError:(dispatch_block_t)block {
    self.onFilesystemError = block;
}

- (void)disableFilesystemIO {}
@end

@interface RetryQueueWrapper () {
    ObjCRetryQueue *_queue;
}
@end

@implementation RetryQueueWrapper

- (instancetype)initWithPath:(NSString *)path {
    if ((self = [super init])) {
        _queue = [[ObjCRetryQueue alloc] initWithPath:path];
    }
    return self;
}

- (void)dealloc {
    // No manual delete needed for ObjC
}

- (void)preStartSetup {
    [_queue preStartSetup];
}

- (void)sweep {
    [_queue sweep];
}

- (NSArray<NSNumber *> *)list {
    return [_queue list];
}

- (id)get:(uint64_t)timestamp {
    NSDictionary *pkg = [_queue get:timestamp];
    return pkg ? pkg[@"payload"] : nil;
}

- (void)remove:(uint64_t)timestamp {
    [_queue remove:timestamp];
}

- (void)setOnFilesystemError:(dispatch_block_t)block {
    [_queue setOnFilesystemError:block];
}

- (void)disableFilesystemIO {
    [_queue disableFilesystemIO];
}

@end
