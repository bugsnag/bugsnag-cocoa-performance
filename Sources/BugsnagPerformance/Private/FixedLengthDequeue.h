//
//  FixedLengthQueue.hpp
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 13.01.25.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#include <deque>

namespace bugsnag {

/**
 * Deque of fixed length that auto-pops the entry at the other end if the length is already at the maximum.
 */
template<class T, class Allocator = std::allocator<T>>
class FixedLengthDequeue: public std::deque<T, Allocator> {
public:
    FixedLengthDequeue(size_t maxSize)
    : std::deque<T, Allocator>()
    , maxSize_(maxSize)
    {}
    void push_back( const T& value ) {
        std::deque<T>::push_back(value);
        popFrontIfOversized();
    }
    void push_back( const T&& value ) {
        std::deque<T>::push_back(value);
        popFrontIfOversized();
    }
    void push_front( const T& value ) {
        std::deque<T>::push_front(value);
        popBackIfOversized();
    }
    void push_front( const T&& value ) {
        std::deque<T>::push_front(value);
        popBackIfOversized();
    }

private:
    void popFrontIfOversized() {
        if(this->size() > maxSize_) {
            this->pop_front();
        }
    }
    void popBackIfOversized() {
        if(this->size() > maxSize_) {
            this->pop_back();
        }
    }
    size_t maxSize_;
};

}
