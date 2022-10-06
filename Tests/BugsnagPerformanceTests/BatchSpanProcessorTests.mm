//
//  BatchSpanProcessorTests.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Private/BatchSpanProcessor.h"
#import "../../Sources/BugsnagPerformance/Private/Span.h"
#import "NoopSpanProcessor.h"

using namespace bugsnag;

class StubSpanExporter : public SpanExporter {
public:
    void exportSpans(std::vector<SpanPtr> spans) noexcept override {
        collected.insert(collected.end(), spans.begin(), spans.end());
    }
    
    std::vector<SpanPtr> collected;
};

@interface BatchSpanProcessorTests : XCTestCase

@end

@implementation BatchSpanProcessorTests

- (void)testBatching {
    auto processor = std::make_shared<BatchSpanProcessor>();
    processor->onEnd(std::make_shared<Span>(@"First", CFAbsoluteTimeGetCurrent(), processor));
    processor->onEnd(std::make_shared<Span>(@"Second", CFAbsoluteTimeGetCurrent(), processor));
    
    auto exporter = std::make_shared<StubSpanExporter>();
    processor->setSpanExporter(exporter);
    XCTAssertEqual(exporter->collected.size(), 2);
    XCTAssertEqualObjects(exporter->collected[0]->name, @"First");
    XCTAssertEqualObjects(exporter->collected[1]->name, @"Second");
}

@end
