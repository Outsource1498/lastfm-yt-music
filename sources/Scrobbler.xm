#import "../headers/Scrobbler.h"
#import <MediaPlayer/MediaPlayer.h>

static NSString *currentSongLocalID = @"";
static double currentTotalMediaTime = 0;
static BOOL scrobbled = NO;
static BOOL isPlaying = NO;
static double currentElapsed = 0;
static NSTimer *timer = nil;
static NSString *lastArtist = @"";
static NSString *lastTrack = @"";

@implementation LFMScrobbler

+ (void) tick {
	if (!isPlaying || scrobbled || currentTotalMediaTime <= 0 || lastArtist.length == 0 || lastTrack.length == 0) return;

	currentElapsed += 1.0;

	if (currentElapsed >= (currentTotalMediaTime / 2.0)) {
		NSLog(@"[LastFM] Scrobbling: %@ - %@ at %.0fs / %.0fs", lastArtist, lastTrack, currentElapsed, currentTotalMediaTime);
		[LFMClient scrobble:lastTrack artist:lastArtist duration:currentTotalMediaTime elapsed:currentElapsed];
		scrobbled = YES;
	}
}

+ (void) startTimer {
	if (timer) return;
	timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
		target:[NSBlockOperation blockOperationWithBlock:^{ [LFMScrobbler tick]; }]
		selector:@selector(main)
		userInfo:nil
		repeats:YES
	];
}

+ (void) poll {
	// Legacy entry point kept for compatibility with Main.xm hooks.
}

+ (void) setCurrentSong:(NSString*)artist track:(NSString*)track duration:(double)duration {
	if (!track || track.length == 0) return;
	if (!artist || artist.length == 0) artist = @"Unknown Artist";
	if (duration <= 0) duration = 0;

	NSString *localID = [NSString stringWithFormat:@"%@ - %@", artist, track];
	if ([currentSongLocalID isEqualToString:localID]) return;

	currentSongLocalID = localID;
	lastArtist = artist;
	lastTrack = track;
	currentTotalMediaTime = duration;
	currentElapsed = 0;
	scrobbled = NO;
	isPlaying = YES;

	NSLog(@"[LastFM] Now Playing: %@ - %@ (%.0fs)", artist, track, duration);
	[LFMClient setNowPlaying:track artist:artist duration:duration];
	[LFMScrobbler startTimer];
}

@end

%hook MPNowPlayingInfoCenter

- (void)setNowPlayingInfo:(NSDictionary *)nowPlayingInfo {
	%orig;

	if (!nowPlayingInfo || nowPlayingInfo.count == 0) {
		NSLog(@"[LastFM] setNowPlayingInfo called with empty info");
		return;
	}

	NSString *artist = nowPlayingInfo[MPMediaItemPropertyArtist];
	NSString *track = nowPlayingInfo[MPMediaItemPropertyTitle];
	NSNumber *duration = nowPlayingInfo[MPMediaItemPropertyPlaybackDuration];

	NSLog(@"[LastFM] MPNowPlayingInfoCenter artist=%@ track=%@ duration=%@", artist, track, duration);

	[LFMScrobbler setCurrentSong:artist track:track duration:duration.doubleValue];
}

%end

%hook MLHAMPlayerItem

- (void) playerStateDidChangeFrom:(NSInteger*)from to:(NSInteger*)to {
	%orig;

	// 3 - Playing
	if ((int)(size_t)to == 3) {
		isPlaying = YES;
	} else {
		isPlaying = NO;
	}
}

%end
