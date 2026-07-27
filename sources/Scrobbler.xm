#import "../headers/Scrobbler.h"
static NSString *currentSongLocalID = @"";
static double currentTotalMediaTime = 0;
static BOOL currentSongReplayed = NO;
static NSTimer *timer = nil;
static BOOL scrobbled = NO;
static BOOL isPlaying = NO;
@implementation LFMScrobbler
+ (void) poll {
	dispatch_async(dispatch_get_main_queue(), ^{
		YTQueueController *controller = [LFMYouTubeInstances queueController];
		if (!controller) return;
		
		YTQueueItem *item = [controller nowPlayingMusicQueueItem];
		if (!item) return;
		
		YTIPlaylistPanelVideoRenderer *renderer = [item videoRenderer];
		if (!renderer) return;
		
		NSString *artist = [[renderer shortBylineText] stringWithFormattingRemoved];
		NSString *track = [[renderer title] stringWithFormattingRemoved];
		if (!artist || !track) return;
		
		double mediaTime = [controller nowPlayingVideoMediaTime];
		NSString *localID = [item localID];
		if (!localID) return;
		
		if ((!currentSongReplayed && [currentSongLocalID isEqualToString:localID] && mediaTime < 1) && isPlaying) {
			currentSongReplayed = YES;
		}
		if ((![currentSongLocalID isEqualToString:localID] || mediaTime > 1) && isPlaying) {
			currentSongReplayed = NO;
		}
		if ((![currentSongLocalID isEqualToString:localID] || currentSongReplayed) && isPlaying) {
			NSLog(@"Now Playing: %@ - %@", artist, track);
			scrobbled = NO;
			currentSongLocalID = localID;
			[LFMClient setNowPlaying:track artist:artist duration:currentTotalMediaTime];
		}
		if (!scrobbled && isPlaying && mediaTime >= (currentTotalMediaTime / 2)) {
			NSLog(@"Scrobbling: %@ - %@", artist, track);
			[LFMClient scrobble:track artist:artist duration:currentTotalMediaTime elapsed:mediaTime];
			scrobbled = YES;
		}
	});
}
@end
%hook MLHAMPlayerItem
- (void) playerStateDidChangeFrom:(NSInteger*)from to:(NSInteger*)to {
	%orig;
	// 3 - Playing
	if ((int)(size_t)to == 3) {
		isPlaying = TRUE;
		dispatch_async(dispatch_get_main_queue(), ^{
			timer = [NSTimer
				scheduledTimerWithTimeInterval:1.0f
				target:[NSBlockOperation blockOperationWithBlock:^{ [LFMScrobbler poll]; }]
				selector:@selector(main)
				userInfo:nil
				repeats:YES
			];
		});
	} else {
		if (timer) {
			[timer invalidate];
		}
		isPlaying = FALSE;
	}
	currentTotalMediaTime = [self totalMediaTime];
}
%end
