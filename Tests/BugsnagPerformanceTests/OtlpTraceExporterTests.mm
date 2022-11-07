//
//  OtlpTraceExporterTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 07.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OtlpTraceExporter.h"

using namespace bugsnag;

class StubUploader: public Uploader {
public:
    StubUploader(UploadResult result)
    : result_(result)
    , uploadAttempts(0)
    {}

    virtual void upload(OtlpPackage &package, UploadResultCallback callback) noexcept override {
        uploadAttempts++;
        callback(result_);
    }
    int uploadAttempts;
    void setNextResult(UploadResult result) {result_ = result;}
private:
    UploadResult result_;
};

@interface OtlpTraceExporterTests : XCTestCase

@end

@implementation OtlpTraceExporterTests

- (void)testUploadSuccessful {
    auto stubUploader = std::make_shared<StubUploader>(BSG_UPLOAD_SUCCESSFUL);
    OtlpTraceExporter exporter(nil, stubUploader);

    std::vector<std::unique_ptr<SpanData>> v;
    v.push_back(std::make_unique<SpanData>(@"First", CFAbsoluteTimeGetCurrent()));
    v.push_back(std::make_unique<SpanData>(@"Second", CFAbsoluteTimeGetCurrent()));
    exporter.exportSpans(std::move(v));
    XCTAssertEqual(stubUploader->uploadAttempts, 1);
    exporter.notifyConnectivityReestablished();
    XCTAssertEqual(stubUploader->uploadAttempts, 1);
    v.push_back(std::make_unique<SpanData>(@"Next", CFAbsoluteTimeGetCurrent()));
    exporter.exportSpans(std::move(v));
    XCTAssertEqual(stubUploader->uploadAttempts, 2);
}

- (void)testCannotRetry {
    auto stubUploader = std::make_shared<StubUploader>(BSG_UPLOAD_FAILED_CANNOT_RETRY);
    OtlpTraceExporter exporter(nil, stubUploader);

    std::vector<std::unique_ptr<SpanData>> v;
    v.push_back(std::make_unique<SpanData>(@"First", CFAbsoluteTimeGetCurrent()));
    v.push_back(std::make_unique<SpanData>(@"Second", CFAbsoluteTimeGetCurrent()));
    exporter.exportSpans(std::move(v));
    XCTAssertEqual(stubUploader->uploadAttempts, 1);
    exporter.notifyConnectivityReestablished();
    XCTAssertEqual(stubUploader->uploadAttempts, 1);
    v.push_back(std::make_unique<SpanData>(@"Next", CFAbsoluteTimeGetCurrent()));
    exporter.exportSpans(std::move(v));
    XCTAssertEqual(stubUploader->uploadAttempts, 2);
}

- (void)testCanRetryConnectivity {
    auto stubUploader = std::make_shared<StubUploader>(BSG_UPLOAD_FAILED_CAN_RETRY);
    OtlpTraceExporter exporter(nil, stubUploader);

    std::vector<std::unique_ptr<SpanData>> v;
    v.push_back(std::make_unique<SpanData>(@"First", CFAbsoluteTimeGetCurrent()));
    v.push_back(std::make_unique<SpanData>(@"Second", CFAbsoluteTimeGetCurrent()));
    exporter.exportSpans(std::move(v));
    XCTAssertEqual(stubUploader->uploadAttempts, 1);
    exporter.notifyConnectivityReestablished();
    XCTAssertEqual(stubUploader->uploadAttempts, 2);
    exporter.notifyConnectivityReestablished();
    XCTAssertEqual(stubUploader->uploadAttempts, 3);
    v.push_back(std::make_unique<SpanData>(@"Next", CFAbsoluteTimeGetCurrent()));
    exporter.exportSpans(std::move(v));
    XCTAssertEqual(stubUploader->uploadAttempts, 4);
    stubUploader->setNextResult(BSG_UPLOAD_SUCCESSFUL);
    exporter.notifyConnectivityReestablished();
    XCTAssertEqual(stubUploader->uploadAttempts, 6);
    exporter.notifyConnectivityReestablished();
    XCTAssertEqual(stubUploader->uploadAttempts, 6);
}

- (void)testCanRetryNewUpload {
    auto stubUploader = std::make_shared<StubUploader>(BSG_UPLOAD_FAILED_CAN_RETRY);
    OtlpTraceExporter exporter(nil, stubUploader);

    std::vector<std::unique_ptr<SpanData>> v;
    v.push_back(std::make_unique<SpanData>(@"First", CFAbsoluteTimeGetCurrent()));
    v.push_back(std::make_unique<SpanData>(@"Second", CFAbsoluteTimeGetCurrent()));
    exporter.exportSpans(std::move(v));
    XCTAssertEqual(stubUploader->uploadAttempts, 1);
    exporter.notifyConnectivityReestablished();
    XCTAssertEqual(stubUploader->uploadAttempts, 2);
    exporter.notifyConnectivityReestablished();
    XCTAssertEqual(stubUploader->uploadAttempts, 3);
    v.push_back(std::make_unique<SpanData>(@"Next", CFAbsoluteTimeGetCurrent()));
    exporter.exportSpans(std::move(v));
    XCTAssertEqual(stubUploader->uploadAttempts, 4);
    stubUploader->setNextResult(BSG_UPLOAD_SUCCESSFUL);
    v.push_back(std::make_unique<SpanData>(@"Next", CFAbsoluteTimeGetCurrent()));
    exporter.exportSpans(std::move(v));
    XCTAssertEqual(stubUploader->uploadAttempts, 7);
    exporter.notifyConnectivityReestablished();
    XCTAssertEqual(stubUploader->uploadAttempts, 7);
    v.push_back(std::make_unique<SpanData>(@"Next", CFAbsoluteTimeGetCurrent()));
    exporter.exportSpans(std::move(v));
    XCTAssertEqual(stubUploader->uploadAttempts, 8);
    exporter.notifyConnectivityReestablished();
    XCTAssertEqual(stubUploader->uploadAttempts, 8);
}

@end
