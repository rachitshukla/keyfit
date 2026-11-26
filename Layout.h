#pragma once
#import <AppKit/AppKit.h>

typedef enum : UInt32 { Maximize = 1, LeftHalf, RightHalf } Layout;

// Accessibility measures down from the top of the primary screen.
static inline CGRect accessibilityFrame(NSRect frame, CGFloat primaryTop) {
    return CGRectMake(NSMinX(frame), primaryTop - NSMaxY(frame),
                      NSWidth(frame), NSHeight(frame));
}

static inline CGRect targetFrame(CGRect available, Layout layout) {
    if (layout == Maximize) return available;
    CGFloat leftWidth = floor(available.size.width / 2);
    if (layout == LeftHalf) {
        available.size.width = leftWidth;
    } else {
        available.origin.x += leftWidth;
        available.size.width -= leftWidth;
    }
    return available;
}
