#import "../Layout.h"
#include <assert.h>
#include <stdio.h>

int main(void) {
    // A display above and to the left of the primary, with an odd usable width.
    CGRect available = accessibilityFrame(NSMakeRect(-1100, 840, 1001, 740), 800);
    assert(CGRectEqualToRect(available, CGRectMake(-1100, -780, 1001, 740)));
    assert(CGRectEqualToRect(targetFrame(available, Maximize), available));
    assert(CGRectEqualToRect(targetFrame(available, LeftHalf), CGRectMake(-1100, -780, 500, 740)));
    assert(CGRectEqualToRect(targetFrame(available, RightHalf), CGRectMake(-600, -780, 501, 740)));
    puts("All three window layouts passed.");
    return 0;
}
