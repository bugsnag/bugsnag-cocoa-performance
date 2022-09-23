//
//  Tracer.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Tracer.h"

#import "Span.h"

void
Tracer::onEnd(const Span &span) {
    // message ExportTraceServiceRequest / message TracesData
    auto request = @{
        
        // An array of ResourceSpans.
        // For data coming from a single resource this array will typically contain
        // one element. Intermediary nodes that receive data from multiple origins
        // typically batch the data before forwarding further and in that case this
        // array will contain multiple elements.
        @"resourceSpans": @[@{
            // A collection of ScopeSpans from a Resource.
            
            // The resource for the spans in this message.
            // If this field is not set then no resource info is known.
            @"resource": @{
                @"attributes": @[@{
                    @"key": @"resource_attribute",
                    @"value": @{
                        @"stringValue": @"something"
                    }
                }]
            },
            
            // A list of ScopeSpans that originate from a resource.
            @"scopeSpans": @[@{
                // A collection of Spans produced by an InstrumentationScope.
                
                // The instrumentation scope information for the spans in this message.
                // Semantically when InstrumentationScope isn't set, it is equivalent with
                // an empty instrumentation scope name (unknown).
                // @"scope": ...
                
                // A list of Spans that originate from an instrumentation scope.
                @"spans": @[span.encode()]
                
                // This schema_url applies to all spans and span events in the "spans" field.
                // @"schemaUrl": ...
            }],
            
            // This schema_url applies to the data in the "resource" field. It does not apply
            // to the data in the "scope_spans" field which have their own schema_url field.
            // @"schemaUrl": ...
        }]
    };
    
    auto data = [NSJSONSerialization dataWithJSONObject:request options:NSJSONWritingPrettyPrinted error:nil];
    
    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    auto urlRequest = [NSMutableURLRequest requestWithURL:endpoint];
    urlRequest.HTTPBody = data;
    urlRequest.HTTPMethod = @"POST";
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//    [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil];
//    [[NSURLSession.sharedSession dataTaskWithRequest:urlRequest] resume];
}
