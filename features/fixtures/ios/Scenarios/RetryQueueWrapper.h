#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RetryQueueWrapper : NSObject

@property (nonatomic, assign) BOOL filesystemIODisabled;

- (instancetype)initWithPath:(NSString *)path;
- (void)preStartSetup;
- (void)sweep;
- (NSArray<NSNumber *> *)list;
- (id)get:(uint64_t)timestamp;
- (void)remove:(uint64_t)timestamp;
- (void)setOnFilesystemError:(dispatch_block_t)block;
- (void)disableFilesystemIO;

@end

NS_ASSUME_NONNULL_END
