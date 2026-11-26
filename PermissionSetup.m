#import <AppKit/AppKit.h>
#import "PermissionSetup.h"

@interface KeyFitSetupAlert : NSAlert
@end

@implementation KeyFitSetupAlert
- (void)openSettings:(id)sender {
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"];
    if (![NSWorkspace.sharedWorkspace openURL:url]) {
        self.informativeText = @"Open the Accessibility privacy settings on your Mac. Enable KeyFit, return here, and click Retry.";
    }
}
@end

Boolean KeyFitCheckPermission(Boolean (*isTrusted)(void)) {
    if (isTrusted()) return true;

    [NSApplication sharedApplication];
    // Allow people to switch back from Settings with Command-Tab during setup.
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];
    KeyFitSetupAlert *alert = [[KeyFitSetupAlert alloc] init];
    alert.messageText = @"Allow KeyFit to move windows";
    alert.informativeText = @"Enable KeyFit in Accessibility settings, then return here and click Retry. If KeyFit is missing, click + and add the app from Applications.";
    [alert addButtonWithTitle:@"Retry"];
    NSButton *settings = [alert addButtonWithTitle:@"Open Accessibility Settings"];
    settings.target = alert;
    settings.action = @selector(openSettings:);
    NSButton *quit = [alert addButtonWithTitle:@"Quit"];
    quit.keyEquivalent = @"\033";
    while ([alert runModal] == NSAlertFirstButtonReturn) {
        if (isTrusted()) {
            [NSApp hide:nil];
            [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
            return true;
        }
        alert.messageText = @"KeyFit still needs Accessibility access";
        alert.informativeText = @"Enable KeyFit in Accessibility settings. If it’s already enabled, remove its entry with −, add the installed app with +, then click Retry.";
    }
    return false;
}
