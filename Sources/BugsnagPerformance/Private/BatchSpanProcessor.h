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
    void onEnd(std::unique_ptr<SpanData> span) noexcept override;
    
    void setSpanExporter(std::shared_ptr<SpanExporter> exporter) noexcept;
    
private:
    std::mutex mutex_;
    std::shared_ptr<SpanExporter> exporter_;
    std::vector<std::unique_ptr<SpanData>> spans_;
};
}
