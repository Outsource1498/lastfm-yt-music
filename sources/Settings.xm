#import "../headers/Settings.h"
#import "../headers/Client.h"
#import "../headers/Instances.h"
#import <SafariServices/SafariServices.h>

@implementation LFMSettingsViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor systemBackgroundColor];
	self.title = @"Last.fm";

	UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:scrollView];

	UIView *contentView = [[UIView alloc] init];
	contentView.translatesAutoresizingMaskIntoConstraints = NO;
	[scrollView addSubview:contentView];

	UILabel *titleLabel = [self lfm_labelWithText:@"Last.fm for YouTube Music" fontSize:22 bold:YES];
	[self lfm_addSubview:titleLabel to:contentView after:nil];

	NSString *username = [LFMClient username];
	NSString *statusText = username && username.length > 0
		? [NSString stringWithFormat:@"Logged in as: %@", username]
		: @"Not logged in";
	UILabel *statusLabel = [self lfm_labelWithText:statusText fontSize:16 bold:NO];
	statusLabel.tag = 1001;
	[self lfm_addSubview:statusLabel to:contentView after:titleLabel];

	NSString *sessionKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"lfmSessionKey"];
	NSString *buttonTitle = sessionKey ? @"Log out" : @"Log in to Last.fm";
	UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[actionButton setTitle:buttonTitle forState:UIControlStateNormal];
	actionButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
	actionButton.tag = 1002;
	[self lfm_addSubview:actionButton to:contentView after:statusLabel];

	if (sessionKey) {
		[actionButton addTarget:self action:@selector(logoutTapped:) forControlEvents:UIControlEventTouchUpInside];
	} else {
		[actionButton addTarget:self action:@selector(loginTapped:) forControlEvents:UIControlEventTouchUpInside];
	}

	UILabel *authorLabel = [self lfm_labelWithText:@"Author: eternal" fontSize:14 bold:NO];
	[self lfm_addSubview:authorLabel to:contentView after:actionButton];

	UILabel *aiLabel = [self lfm_labelWithText:@"AI was used for updating classes" fontSize:12 bold:NO];
	aiLabel.textColor = [UIColor secondaryLabelColor];
	[self lfm_addSubview:aiLabel to:contentView after:authorLabel];

	UILabel *versionLabel = [self lfm_labelWithText:@"v0.0.2" fontSize:12 bold:NO];
	versionLabel.textColor = [UIColor secondaryLabelColor];
	[self lfm_addSubview:versionLabel to:contentView after:aiLabel];

	[NSLayoutConstraint activateConstraints:@[
		[contentView.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:20],
		[contentView.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor constant:20],
		[contentView.trailingAnchor constraintEqualToAnchor:scrollView.trailingAnchor constant:-20],
		[contentView.widthAnchor constraintEqualToAnchor:scrollView.widthAnchor constant:-40],
		[contentView.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:-20]
	]];
}

- (UILabel*)lfm_labelWithText:(NSString*)text fontSize:(CGFloat)fontSize bold:(BOOL)bold {
	UILabel *label = [[UILabel alloc] init];
	label.translatesAutoresizingMaskIntoConstraints = NO;
	label.text = text;
	label.textAlignment = NSTextAlignmentCenter;
	label.numberOfLines = 0;
	if (bold) {
		label.font = [UIFont boldSystemFontOfSize:fontSize];
	} else {
		label.font = [UIFont systemFontOfSize:fontSize];
	}
	label.textColor = [UIColor labelColor];
	return label;
}

- (void)lfm_addSubview:(UIView*)subview to:(UIView*)containerView after:(UIView*)previousView {
	[containerView addSubview:subview];
	if (previousView) {
		[NSLayoutConstraint activateConstraints:@[
			[subview.topAnchor constraintEqualToAnchor:previousView.bottomAnchor constant:16],
			[subview.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
			[subview.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor]
		]];
	} else {
		[NSLayoutConstraint activateConstraints:@[
			[subview.topAnchor constraintEqualToAnchor:containerView.topAnchor],
			[subview.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
			[subview.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor]
		]];
	}
}

- (void)loginTapped:(id)sender {
	[LFMClient createToken];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)logoutTapped:(id)sender {
	[LFMClient logout];
	[self dismissViewControllerAnimated:YES completion:nil];
}

+ (void)showFromViewController:(UIViewController *)viewController {
	LFMSettingsViewController *vc = [[LFMSettingsViewController alloc] init];
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
	[viewController presentViewController:nav animated:YES completion:nil];
}

@end
