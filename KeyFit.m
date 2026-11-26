#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>

#import "Layout.h"

static const OSType signature = 'KFit';

static NSScreen *screenForWindow(CGRect window, NSArray<NSScreen *> *screens,
                                 CGFloat primaryTop) {
    NSScreen *best = nil;
    CGFloat largestArea = 0;
    for (NSScreen *screen in screens) {
        CGRect bounds = accessibilityFrame(screen.frame, primaryTop);
        CGRect overlap = CGRectIntersection(bounds, window);
        if (CGRectIsEmpty(overlap)) continue;
        CGFloat area = overlap.size.width * overlap.size.height;
        if (area > largestArea) {
            largestArea = area;
            best = screen;
        }
    }
    return best ?: NSScreen.mainScreen;
}

static id attribute(AXUIElementRef element, CFStringRef key) {
    CFTypeRef result = NULL;
    AXUIElementCopyAttributeValue(element, key, &result);
    return CFBridgingRelease(result);
}

static BOOL readGeometry(id value, AXValueType type, void *output) {
    return value && CFGetTypeID((__bridge CFTypeRef)value) == AXValueGetTypeID()
        && AXValueGetValue((__bridge AXValueRef)value, type, output);
}

static BOOL windowFrame(AXUIElementRef window, CGRect *frame) {
    // All shortcuts run on the main thread. Cache only the attribute names.
    static NSArray *names;
    if (!names) names = @[(__bridge NSString *)kAXPositionAttribute,
                          (__bridge NSString *)kAXSizeAttribute, @"AXFullScreen"];
    CFArrayRef result = NULL;
    AXError status = AXUIElementCopyMultipleAttributeValues(window,
        (__bridge CFArrayRef)names, 0, &result);
    NSArray *values = CFBridgingRelease(result);
    if (status == kAXErrorSuccess && values.count == 3) {
        if ([values[2] isEqual:@YES]) return NO;
        if (readGeometry(values[0], kAXValueTypeCGPoint, &frame->origin)
            && readGeometry(values[1], kAXValueTypeCGSize, &frame->size)) return YES;
    } else if (status != kAXErrorNotImplemented && status != kAXErrorAttributeUnsupported
               && status != kAXErrorSuccess) {
        return NO;
    }
    // Some apps only implement the individual attribute queries.
    return ![attribute(window, CFSTR("AXFullScreen")) boolValue]
        && readGeometry(attribute(window, kAXPositionAttribute), kAXValueTypeCGPoint, &frame->origin)
        && readGeometry(attribute(window, kAXSizeAttribute), kAXValueTypeCGSize, &frame->size);
}

static BOOL writable(AXUIElementRef window, CFStringRef key) {
    Boolean settable = false;
    return AXUIElementIsAttributeSettable(window, key, &settable) == kAXErrorSuccess
        && settable;
}

static void snap(Layout layout) {
    pid_t pid = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
    if (pid <= 0) return;
    AXUIElementRef app = AXUIElementCreateApplication(pid);
    AXUIElementSetMessagingTimeout(app, 0.3f);
    __attribute__((objc_precise_lifetime)) id focused = attribute(app, kAXFocusedWindowAttribute);
    CFRelease(app);
    if (!focused || CFGetTypeID((__bridge CFTypeRef)focused) != AXUIElementGetTypeID()) return;
    AXUIElementRef window = (__bridge AXUIElementRef)focused;
    AXUIElementSetMessagingTimeout(window, 0.3f);
    CGRect current;
    if (!windowFrame(window, &current)) return;
    NSArray<NSScreen *> *screens = NSScreen.screens;
    if (!screens.count) return;
    CGFloat primaryTop = NSMaxY(screens.firstObject.frame);
    NSScreen *screen = screens.count == 1 ? screens.firstObject
                                          : screenForWindow(current, screens, primaryTop);
    CGRect target = targetFrame(accessibilityFrame(screen.visibleFrame, primaryTop), layout);
    if (CGRectEqualToRect(current, target)) return;
    if (!writable(window, kAXPositionAttribute) || !writable(window, kAXSizeAttribute)) return;

    BOOL moves = !CGPointEqualToPoint(current.origin, target.origin);
    BOOL shrinks = target.size.width < current.size.width || target.size.height < current.size.height;
    BOOL grows = target.size.width > current.size.width || target.size.height > current.size.height;
    AXValueRef size = (shrinks || grows) ? AXValueCreate(kAXValueTypeCGSize, &target.size) : NULL;
    if (moves && shrinks) AXUIElementSetAttributeValue(window, kAXSizeAttribute, size);
    if (moves) {
        AXValueRef position = AXValueCreate(kAXValueTypeCGPoint, &target.origin);
        AXUIElementSetAttributeValue(window, kAXPositionAttribute, position);
        CFRelease(position);
    }
    // Grow at the final origin, where the screen edge won't clip the window.
    if (size && (!moves || grows))
        AXUIElementSetAttributeValue(window, kAXSizeAttribute, size);
    if (size) CFRelease(size);
}

static OSStatus pressed(EventHandlerCallRef next, EventRef event, void *context) {
    EventHotKeyID key;
    OSStatus status = GetEventParameter(event, kEventParamDirectObject,
                                        typeEventHotKeyID, NULL, sizeof(key), NULL, &key);
    if (status != noErr || key.signature != signature || key.id < Maximize || key.id > RightHalf)
        return eventNotHandledErr;
    @autoreleasepool { snap((Layout)key.id); }
    return noErr;
}

static void showError(NSString *message) {
    [NSApplication sharedApplication];
    [NSApp activateIgnoringOtherApps:YES];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"KeyFit couldn’t start";
    alert.informativeText = message;
    [alert runModal];
}

int main(void) {
    @autoreleasepool {
        NSDictionary *options = @{(__bridge NSString *)kAXTrustedCheckOptionPrompt: @YES};
        if (!AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options)) return 0;

        EventTypeSpec type = {kEventClassKeyboard, kEventHotKeyPressed};
        if (InstallApplicationEventHandler(&pressed, 1, &type, NULL, NULL) != noErr) {
            showError(@"macOS could not install the keyboard shortcut handler. Open KeyFit again to retry.");
            return 1;
        }
        const struct { Layout layout; UInt32 code; NSString *label; } bindings[] = {
            {Maximize, kVK_UpArrow, @"⌘↑"}, {LeftHalf, kVK_LeftArrow, @"⌘←"},
            {RightHalf, kVK_RightArrow, @"⌘→"}
        };
        EventHotKeyRef keys[3] = {NULL};
        for (size_t i = 0; i < sizeof(bindings) / sizeof(bindings[0]); ++i) {
            EventHotKeyID key = {signature, bindings[i].layout};
            OSStatus status = RegisterEventHotKey(bindings[i].code, cmdKey, key,
                GetApplicationEventTarget(), kEventHotKeyExclusive, &keys[i]);
            if (status != noErr) {
                for (size_t j = 0; j < i; ++j) UnregisterEventHotKey(keys[j]);
                showError([NSString stringWithFormat:
                    @"macOS could not register %@ (error %d). Quit BetterSnapTool or release the shortcut in the app using it, then open KeyFit again.",
                    bindings[i].label, (int)status]);
                return 1;
            }
        }
    }
    EventTargetRef dispatcher = GetEventDispatcherTarget();
    for (;;) {
        @autoreleasepool {
            EventRef event = NULL;
            OSStatus status = ReceiveNextEvent(0, NULL, kEventDurationForever, true, &event);
            if (status != noErr) return status == eventLoopQuitErr ? 0 : 1;
            SendEventToEventTarget(event, dispatcher);
            ReleaseEvent(event);
        }
    }
}
