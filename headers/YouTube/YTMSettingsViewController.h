#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// YouTube Music Settings view controller
@interface YTMSettingsViewController : UIViewController
@end

// Forward declarations for %new methods added by our tweak
@interface YTMSettingsViewController (LFMPatch)
- (UIView *)lfm_findScrollViewInView:(UIView *)view excluding:(UIView *)exclude;
- (void)lfm_updateStatusLabel;
- (void)lfm_userDefaultsChanged:(NSNotification *)note;
- (void)lfm_settingsTapped;
@end
