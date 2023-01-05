//
//  BatchSpanProcessorTests.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Private/BatchSpanProcessor.h"
#import "../../Sources/BugsnagPerformance/Private/Sampler.h"
#import "../../Sources/BugsnagPerformance/Private/Span.h"
#import "../../Sources/BugsnagPerformance/Private/BSGInternalConfig.h"


using namespace bugsnag;

class StubSpanExporter : public SpanExporter {
public:
    void exportSpans(std::vector<std::unique_ptr<SpanData>> spans) noexcept override {
        std::move(spans.begin(), spans.end(), std::back_inserter(collected));
    }
    
    std::vector<std::unique_ptr<SpanData>> collected;
};

@interface BatchSpanProcessorTests : XCTestCase

@end

@implementation BatchSpanProcessorTests

- (void)testBatching {
    BatchSpanProcessor processor(std::make_shared<Sampler>(1.0));
    processor.onEnd(std::make_unique<SpanData>(@"First", CFAbsoluteTimeGetCurrent()));
    processor.onEnd(std::make_unique<SpanData>(@"Second", CFAbsoluteTimeGetCurrent()));
    
    auto exporter = std::make_shared<StubSpanExporter>();
    processor.setSpanExporter(exporter);
    XCTAssertEqual(exporter->collected.size(), 2);
    XCTAssertEqualObjects(exporter->collected[0]->name, @"First");
    XCTAssertEqualObjects(exporter->collected[1]->name, @"Second");
}

- (void)testAutoSendOnBatchFull {
    const int entriesBeforeForcedExport = 20;
    bsgp_autoTriggerExportOnBatchSize = entriesBeforeForcedExport;

    BatchSpanProcessor processor(std::make_shared<Sampler>(1.0));
    auto exporter = std::make_shared<StubSpanExporter>();
    processor.setSpanExporter(exporter);

    int i;
    for (i = 1; i <= entriesBeforeForcedExport-1; i++) {
        processor.onEnd(std::make_unique<SpanData>([NSString stringWithFormat:@"#%d", i], CFAbsoluteTimeGetCurrent()));
        XCTAssertEqual(exporter->collected.size(), 0);
    }
    processor.onEnd(std::make_unique<SpanData>([NSString stringWithFormat:@"#%d", i], CFAbsoluteTimeGetCurrent()));

    XCTAssertEqual(exporter->collected.size(), entriesBeforeForcedExport);
    if (exporter->collected.size() == entriesBeforeForcedExport) {
        XCTAssertEqualObjects(exporter->collected[0]->name, @"#1");
        XCTAssertEqualObjects(exporter->collected[i-1]->name, @"#20");
    }
}

- (void)testAutoSendOnTimeout {
    bsgp_autoTriggerExportOnTimeDuration = 10 * NSEC_PER_MSEC;
    BatchSpanProcessor processor(std::make_shared<Sampler>(1.0));
    auto exporter = std::make_shared<StubSpanExporter>();
    processor.setSpanExporter(exporter);

    processor.onEnd(std::make_unique<SpanData>(@"First", CFAbsoluteTimeGetCurrent()));
    XCTAssertEqual(exporter->collected.size(), 0);
    sleep(1);

    XCTAssertEqual(exporter->collected.size(), 1);
    if (exporter->collected.size() == 2) {
        XCTAssertEqualObjects(exporter->collected[0]->name, @"First");
    }
}

- (void)testAutoSendNoTimeout {
    bsgp_autoTriggerExportOnTimeDuration = 10 * NSEC_PER_MSEC;
    BatchSpanProcessor processor(std::make_shared<Sampler>(1.0));
    auto exporter = std::make_shared<StubSpanExporter>();
    processor.setSpanExporter(exporter);

    processor.onEnd(std::make_unique<SpanData>(@"First", CFAbsoluteTimeGetCurrent()));
    processor.onEnd(std::make_unique<SpanData>(@"Second", CFAbsoluteTimeGetCurrent()));

    XCTAssertEqual(exporter->collected.size(), 0);
}

@end
