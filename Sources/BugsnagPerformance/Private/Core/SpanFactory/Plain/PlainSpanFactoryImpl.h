//
//  PlainSpanFactoryImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 15/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "PlainSpanFactory.h"
#import "PlainSpanFactoryCallbacks.h"
#import "../../Attributes/SpanAttributesProvider.h"
#import "../../Sampler/Sampler.h"
#import "../../SpanStack/SpanStackingHandler.h"

namespace bugsnag {

class PlainSpanFactoryImpl: public PlainSpanFactory {
public:
    PlainSpanFactoryImpl(std::shared_ptr<Sampler> sampler,
                         std::shared_ptr<SpanStackingHandler> spanStackingHandler,
                         std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
    : sampler_(sampler)
    , spanStackingHandler_(spanStackingHandler)
    , spanAttributesProvider_(spanAttributesProvider) {}
    
    BugsnagPerformanceSpan *startSpan(NSString *name,
                                      const SpanOptions &options,
                                      BSGTriState defaultFirstClass,
                                      NSDictionary *attributes,
                                      NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;
    
    BugsnagPerformanceSpan *startSpan(NSString *name,
                                      const SpanOptions &options,
                                      BSGTriState defaultFirstClass,
                                      SpanKind kind,
                                      NSDictionary *attributes,
                                      NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;
    
    void setup(PlainSpanFactoryCallbacks *callbacks) noexcept {
        callbacks_ = callbacks;
    }
    
    void setAttributeCountLimit(NSUInteger limit) noexcept {
        attributeCountLimit_ = limit;
    }
    
private:
    std::shared_ptr<Sampler> sampler_;
    std::shared_ptr<SpanStackingHandler> spanStackingHandler_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    PlainSpanFactoryCallbacks *callbacks_;
    NSUInteger attributeCountLimit_{128};
    
    PlainSpanFactoryImpl() = delete;
};
}
