#import <AppKit/AppKit.h>
#import "../PermissionSetup.h"
#include <assert.h>

static Boolean trusted;
static unsigned checks;
static Boolean checkPermission(void) {
    ++checks;
    return trusted;
}

static NSButton *buttonNamed(NSView *view, NSString *title) {
    if ([view isKindOfClass:NSButton.class] && [[(NSButton *)view title] isEqualToString:title])
        return (NSButton *)view;
    for (NSView *child in view.subviews) {
        NSButton *button = buttonNamed(child, title);
        if (button) return button;
    }
    return nil;
}

int main(void) {
    @autoreleasepool {
        // An approved launch should reach the shortcuts without starting AppKit.
        trusted = true;
        assert(KeyFitCheckPermission(checkPermission) && checks == 1 && NSApp == nil);
        trusted = false;
        [NSApplication sharedApplication];

        // Drive the actual setup window in this process. The test controls only
        // the result of the permission check and never changes macOS privacy settings.
        __block unsigned step = 0;
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:10];
        NSTimer *driver = [NSTimer timerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *timer) {
            NSWindow *window = NSApp.modalWindow;
            assert(deadline.timeIntervalSinceNow > 0);
            if (!window) return;
            NSButton *settings = buttonNamed(window.contentView, @"Open Accessibility Settings");
            assert(settings && [settings.target respondsToSelector:settings.action]);
            assert([NSStringFromSelector(settings.action) isEqualToString:@"openSettings:"]);
            NSButton *button = buttonNamed(window.contentView, step == 2 ? @"Quit" : @"Retry");
            assert(button != nil);
            trusted = step == 1;
            ++step;
            assert([NSApp sendAction:button.action to:button.target from:button]);
        }];
        [NSRunLoop.mainRunLoop addTimer:driver forMode:NSModalPanelRunLoopMode];
        assert(KeyFitCheckPermission(checkPermission));
        assert(step == 2 && checks == 4);
        assert(NSApp.activationPolicy == NSApplicationActivationPolicyAccessory);
        trusted = false;
        assert(!KeyFitCheckPermission(checkPermission));
        assert(step == 3 && checks == 5);
        [driver invalidate];
        puts("Approved launch, denied Retry, successful Retry, and Quit passed.");
    }
}
