#import "../headers/Settings.h"
#import "../headers/Client.h"
#import "../headers/Instances.h"
#import <SafariServices/SafariServices.h>

@implementation LFMSettingsViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
	self.title = @"Last.fm Scrobbler";
	
	// Add a Done button for modal dismissal
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped)];

	UITableViewStyle style = UITableViewStyleInsetGrouped;
	CGRect frame = self.view.bounds;
	self.tableView = [[UITableView alloc] initWithFrame:frame style:style];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.scrollEnabled = YES;
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
	[self.view addSubview:self.tableView];
	
	// Observe login/logout changes to reload table live
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(lfm_userDefaultsChanged:)
		name:NSUserDefaultsDidChangeNotification
		object:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)lfm_userDefaultsChanged:(NSNotification *)note {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.tableView reloadData];
	});
}

- (void)doneTapped {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	// Refresh username when the view appears (async, table updates via notification)
	if ([[NSUserDefaults standardUserDefaults] stringForKey:@"lfmSessionKey"]) {
		[LFMClient refreshUsername];
	}
	[self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0: return 1; // Account / login status
		case 1: return 1; // Login/logout button
		case 2: return 3; // Info rows (author, AI note, version)
		default: return 0;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0: return @"Account";
		case 1: return @"";
		case 2: return @"About";
		default: return nil;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	cell.selectionStyle = UITableViewCellSelectionStyleDefault;
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.textAlignment = NSTextAlignmentNatural;
	cell.textLabel.textColor = [UIColor labelColor];
	
	switch (indexPath.section) {
		case 0: {
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			NSString *username = [LFMClient username];
			if (username && username.length > 0) {
				cell.textLabel.text = [NSString stringWithFormat:@"Logged in as %@", username];
				cell.textLabel.textColor = [UIColor systemGreenColor];
				cell.imageView.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
				cell.imageView.tintColor = [UIColor systemGreenColor];
			} else {
				cell.textLabel.text = @"Not connected to Last.fm";
				cell.textLabel.textColor = [UIColor secondaryLabelColor];
				cell.imageView.image = [UIImage systemImageNamed:@"exclamationmark.circle"];
				cell.imageView.tintColor = [UIColor systemOrangeColor];
			}
			break;
		}
		case 1: {
			cell.textLabel.textAlignment = NSTextAlignmentCenter;
			NSString *sessionKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"lfmSessionKey"];
			if (sessionKey) {
				cell.textLabel.text = @"Log Out";
				cell.textLabel.textColor = [UIColor systemRedColor];
			} else {
				cell.textLabel.text = @"Connect to Last.fm";
				cell.textLabel.textColor = [UIColor systemBlueColor];
			}
			break;
		}
		case 2: {
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = @"Author: eternal";
					cell.textLabel.textColor = [UIColor secondaryLabelColor];
					break;
				case 1:
					cell.textLabel.text = @"AI was used for updating classes";
					cell.textLabel.textColor = [UIColor secondaryLabelColor];
					cell.textLabel.font = [UIFont systemFontOfSize:14];
					break;
				case 2:
					cell.textLabel.text = @"v0.0.2";
					cell.textLabel.textColor = [UIColor tertiaryLabelColor];
					cell.textLabel.font = [UIFont systemFontOfSize:13];
					break;
			}
			break;
		}
	}
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == 1 && indexPath.row == 0) {
		NSString *sessionKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"lfmSessionKey"];
		if (sessionKey) {
			[LFMClient logout];
			[self.tableView reloadData];
		} else {
			[LFMClient createToken];
			[self dismissViewControllerAnimated:YES completion:nil];
		}
	}
}

+ (void)showFromViewController:(UIViewController *)viewController {
	LFMSettingsViewController *vc = [[LFMSettingsViewController alloc] init];
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
	[viewController presentViewController:nav animated:YES completion:nil];
}

@end
