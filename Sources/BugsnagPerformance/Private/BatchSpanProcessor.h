//
//  BatchSpanProcessor.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import "SpanExporter.h"
#import "SpanProcessor.h"

#import <mutex>

namespace bugsnag {
/**
 * A span processor that batches spans before passing them to an exporter.
 */
class BatchSpanProcessor: public SpanProcessor {
public:
    BatchSpanProcessor(std::shared_ptr<class Sampler> sampler) noexcept;
    ~BatchSpanProcessor() noexcept;

    void onEnd(std::unique_ptr<SpanData> span) noexcept override;
    
    void setSpanExporter(std::shared_ptr<SpanExporter> exporter) noexcept;
    
private:
    bool shouldSample(std::unique_ptr<SpanData> &span) noexcept;

    static void notificationCallback(CFNotificationCenterRef center,
                                     void *observer,
                                     CFNotificationName name,
                                     const void *object,
                                     CFDictionaryRef userInfo) noexcept;

    bool tryExportSpans() noexcept;
    void exportSpans() noexcept;

    void startTimer() noexcept;
    void stopTimer() noexcept;

    void(^timerCallback)();
    std::mutex mutex_;
    std::shared_ptr<SpanExporter> exporter_;
    std::shared_ptr<class Sampler> sampler_;
    std::vector<std::unique_ptr<SpanData>> spans_;
    NSMutableData *timerCallbackValidityMarker;
};
}
