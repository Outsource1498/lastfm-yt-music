#import "../headers/Main.h"
#import "../headers/YouTube/YTMSettingsViewController.h"

#pragma mark - YTMContentViewController (main screen)
%hook YTMContentViewController
- (void) viewDidLoad {
	%orig;
	NSLog(@"Started.");
}
%end

#pragma mark - YTMSettingsViewController (settings screen)
%hook YTMSettingsViewController
- (void)viewDidLoad {
	%orig;
	
	// Only add the row once
	if ([self.view viewWithTag:9999]) return;
	
	// ── Create a native-looking Last.fm settings row ──
	UIView *lfmRow = [[UIView alloc] init];
	lfmRow.translatesAutoresizingMaskIntoConstraints = NO;
	lfmRow.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
	lfmRow.layer.cornerRadius = 10;
	lfmRow.tag = 9999;
	
	// Icon label
	UILabel *iconLabel = [[UILabel alloc] init];
	iconLabel.translatesAutoresizingMaskIntoConstraints = NO;
	iconLabel.text = @"🎵";
	iconLabel.font = [UIFont systemFontOfSize:20];
	
	// Title
	UILabel *titleLabel = [[UILabel alloc] init];
	titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	titleLabel.text = @"Last.fm Scrobbler";
	titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
	
	// Status subtitle
	UILabel *statusLabel = [[UILabel alloc] init];
	statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
	NSString *username = [LFMClient username];
	statusLabel.text = username ? [NSString stringWithFormat:@"Connected: %@", username] : @"Not connected";
	statusLabel.font = [UIFont systemFontOfSize:12];
	statusLabel.textColor = [UIColor secondaryLabelColor];
	statusLabel.tag = 9998;
	
	// Disclosure chevron
	UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
	chevron.translatesAutoresizingMaskIntoConstraints = NO;
	chevron.tintColor = [UIColor tertiaryLabelColor];
	[chevron setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
	
	// Tap gesture
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lfm_settingsTapped)];
	[lfmRow addGestureRecognizer:tap];
	lfmRow.userInteractionEnabled = YES;
	
	[lfmRow addSubview:iconLabel];
	[lfmRow addSubview:titleLabel];
	[lfmRow addSubview:statusLabel];
	[lfmRow addSubview:chevron];
	[self.view addSubview:lfmRow];
	
	[NSLayoutConstraint activateConstraints:@[
		[lfmRow.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
		[lfmRow.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
		[lfmRow.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
		[lfmRow.heightAnchor constraintGreaterThanOrEqualToConstant:56],
		
		[iconLabel.centerYAnchor constraintEqualToAnchor:lfmRow.centerYAnchor],
		[iconLabel.leadingAnchor constraintEqualToAnchor:lfmRow.leadingAnchor constant:12],
		[iconLabel.widthAnchor constraintEqualToConstant:28],
		
		[titleLabel.topAnchor constraintEqualToAnchor:lfmRow.topAnchor constant:8],
		[titleLabel.leadingAnchor constraintEqualToAnchor:iconLabel.trailingAnchor constant:12],
		[titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:chevron.leadingAnchor constant:-8],
		
		[statusLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:1],
		[statusLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
		[statusLabel.bottomAnchor constraintEqualToAnchor:lfmRow.bottomAnchor constant:-8],
		
		[chevron.centerYAnchor constraintEqualToAnchor:lfmRow.centerYAnchor],
		[chevron.trailingAnchor constraintEqualToAnchor:lfmRow.trailingAnchor constant:-12],
	]];
	
	// Push collection view content below our row (recursive search)
	dispatch_async(dispatch_get_main_queue(), ^{
		UIView *scrollView = [self lfm_findScrollViewInView:self.view excluding:lfmRow];
		if ([scrollView isKindOfClass:[UIScrollView class]]) {
			UIScrollView *sv = (UIScrollView *)scrollView;
			UIEdgeInsets insets = sv.contentInset;
			if (insets.top < 80) {
				insets.top += 72;
				sv.contentInset = insets;
				sv.scrollIndicatorInsets = insets;
			}
		}
	});
	
	// Observe login/logout changes to update status live
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(lfm_userDefaultsChanged:)
		name:NSUserDefaultsDidChangeNotification
		object:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	%orig;
}

%new
- (UIView *)lfm_findScrollViewInView:(UIView *)view excluding:(UIView *)exclude {
	if (view == exclude) return nil;
	if ([view isKindOfClass:[UIScrollView class]]) return view;
	for (UIView *subview in view.subviews) {
		UIView *found = [self lfm_findScrollViewInView:subview excluding:exclude];
		if (found) return found;
	}
	return nil;
}

%new
- (void)lfm_updateStatusLabel {
	UIView *row = [self.view viewWithTag:9999];
	if (!row) return;
	UILabel *statusLabel = [row viewWithTag:9998];
	if (!statusLabel) return;
	NSString *username = [LFMClient username];
	statusLabel.text = username ? [NSString stringWithFormat:@"Connected: %@", username] : @"Not connected";
}

%new
- (void)lfm_userDefaultsChanged:(NSNotification *)note {
	[self lfm_updateStatusLabel];
}

%new
- (void)lfm_settingsTapped {
	[LFMSettingsViewController showFromViewController:self];
}
%end
%hook YTMQueueModificationNotifier
- (void) queueController:(id)controller didReplacePlaylistWithPlaylistPanel:(id)panel {
	%orig;
	[LFMScrobbler poll];
}
- (void) queueControllerDidRemoveAllItems:(id)items {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller didAddItemsFromResponse:(id)response {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller didUpdateVideoAtIndex:(unsigned long long)index {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller didRemoveVideoAtIndexPath:(id)path {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller numberOfItemsDidChangeFrom:(unsigned long long)from to:(unsigned long long)to nowPlayingIndexChanged:(_Bool)changed {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller didInsertVideoCount:(unsigned long long)count atIndex:(unsigned long long)index {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller didInsertAutoplayRenderersAtIndexes:(id)indexes {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller didRemoveAutoplayRenderersAtIndexes:(id)indexes {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller didPromoteAutoplayItemsAtIndexPaths:(id)paths userTriggered:(_Bool)triggered {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller didMoveVideoAtIndexPath:(id)prevPath toIndexPath:(id)toPath {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller didUpdateUserContentMode:(unsigned long long)mode {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller didUpdateShuffleMode:(unsigned long long)mode {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller didUpdateLoopMode:(unsigned long long)mode {
	%orig;
	[LFMScrobbler poll];
};
- (void) queueController:(id)controller nowPlayingItemAtIndex:(unsigned long long)index {
	%orig;
	[LFMScrobbler poll];
};
%end
