#import <ApplicationServices/ApplicationServices.h>

// The check runs once at launch and again only when the user clicks Retry.
Boolean KeyFitCheckPermission(Boolean (*isTrusted)(void));
