#import <UIKit/UIKit.h>

@interface LFMSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

+ (void)showFromViewController:(UIViewController *)viewController;

@end
