//
//  BatchSpanProcessorTests.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Private/BatchSpanProcessor.h"
#import "../../Sources/BugsnagPerformance/Private/Span.h"

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
    BatchSpanProcessor processor;
    processor.onEnd(std::make_unique<SpanData>(@"First", CFAbsoluteTimeGetCurrent()));
    processor.onEnd(std::make_unique<SpanData>(@"Second", CFAbsoluteTimeGetCurrent()));
    
    auto exporter = std::make_shared<StubSpanExporter>();
    processor.setSpanExporter(exporter);
    XCTAssertEqual(exporter->collected.size(), 2);
    XCTAssertEqualObjects(exporter->collected[0]->name, @"First");
    XCTAssertEqualObjects(exporter->collected[1]->name, @"Second");
}

@end
