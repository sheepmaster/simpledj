//
//  DeckController.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 13.07.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "DeckController.h"
#import "DJController.h"
#import "QTMovie+SimpleDJ.h"
#import "Song.h"

#define UPDATE_INTERVAL 0.053
#define AUTO_FADE_INTERVAL (1.0/30)

@implementation DeckController

- (void)awakeFromNib {
	NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
	[controller addObserver:self 
				 forKeyPath:@"values.CueVolume" 
					options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
					context:nil];
	[controller addObserver:self 
				 forKeyPath:@"values.FadeInTime" 
					options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
					context:nil];
	[controller addObserver:self 
				 forKeyPath:@"values.FadeOutTime" 
					options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
					context:nil];
	[controller addObserver:self 
				 forKeyPath:@"values.AdvanceWarningTime" 
					options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
					context:nil];
}

- (void)dealloc {
	[movie release];
	[song release];
	[updateTimer release];
	[autoFadeTimer release];
	[autoFadeStartTimer release];
	[activeOutputDevice release];
	
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//	NSLog(@"keyPath: %@ of object %@ changed: %@", keyPath, object, change);
	if ([keyPath isEqualTo:@"values.CueVolume"]) {
		[self cueVolumeChanged:[[object valueForKeyPath:@"values.CueVolume"] floatValue]];
	} else if ([keyPath isEqualTo:@"values.FadeOutTime"] || [keyPath isEqualTo:@"values.FadeInTime"] || [keyPath isEqualTo:@"values.AdvanceWarningTime"]) {
		[self updateAdvanceWarning];
	}
}


- (IBAction)cue:(id)sender {
//	if (autoFadeTimer) {
//		[self setVolumeUpdatingMaster:autoFadeStartVolume];
//	}
	[self pause:sender];
	[movie setCurrentTimeInSeconds:cuePosition];
	[playbackController resetAutoFade];
	cuePosition = 0.0;
}

- (IBAction)skip:(id)sender {
	[self pause:sender];
	[playbackController advanceSongForDeck:self];
}

- (IBAction)scrub:(id)sender {
	float newScrubPosition = [sender floatValue];
	if (newScrubPosition != scrubPosition) {
		scrubPosition = newScrubPosition;
		[self setPosition:scrubPosition];
	}
}

- (IBAction)play:(id)sender {
	if (![self isPlaying]) {
		cuePosition = [movie currentTimeInSeconds];
		[player play:sender];
		if (IOPMAssertionCreate(kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn, &assertionID) != kIOReturnSuccess) {
			NSLog(@"Couldn't create assertion kIOPMAssertionTypeNoDisplaySleep");
		}
		[playPauseButton setImage:[NSImage imageNamed:@"PauseTemplate"]];
//		[playPauseButton setTitle:PauseSymbol];
		
		if (!moviePlayed && !cueActive) {
			[song setDatePlayed:[NSDate date]];
			[historyController addObject:song];
			[historyController rearrangeObjects];
			moviePlayed = YES;
		}
		
		[playbackController updateAutoFadeStatus];
		[playbackController updateEditedStatus];
	}
}

- (IBAction)pause:(id)sender {
	[player pause:sender];
	IOPMAssertionRelease(assertionID);
	[playPauseButton setImage:[NSImage imageNamed:@"PlayTemplate"]];
//	[playPauseButton setTitle:PlaySymbol];
	[self setCueActive:NO];
	[playbackController cancelAutoFade];
	[playbackController updateEditedStatus];
}

- (IBAction)playPause:(id)sender {
	if (![self isPlaying]) {
		[self play:sender];
		NSEvent* event = [NSApp currentEvent];
//		NSLog(@"current event: %@", event);
//		NSLog(@"volume: %f", [self volume]);
		if ([event modifierFlags] & NSShiftKeyMask) {
			[playbackController startAutoFadeFadingInDeck:self fadingOutDeck:other offset:0.0];
		}
	} else {
		[self pause:sender];
	}
}

- (IBAction)clearMovie:(id)sender {
	[self pause:sender];
	[self stopMovie];
	[self setSong:nil];
	movie = nil;
	[self update:nil];
	[playbackController saveLoadedSongs];
	[playbackController updateAutoFadeStatus];
}

- (IBAction)eavesdrop:(id)sender {
	if ([self isPlaying]) {
		[self setCueActive:!cueActive];
	} else {
		[self setCueActive:YES];
		[self play:sender];
	}
}

- (float)volume {
	return volume;
}

- (void)setVolume:(float)newVolume {
//	NSLog(@"[%@ setVolume: %f]", self, newVolume);
	
	volume = newVolume;
	if (!cueActive) {
		[movie setVolume:newVolume];
	}
	
	[volumeSlider setFloatValue:newVolume];
}

- (BOOL)isPlaying {
	return ([movie rate] > 0);
}

- (BOOL)autoFadeActive {
	return (autoFadeTimer != nil);
}

- (void)setVolumeUpdatingMaster:(float)newVolume {
	[self setVolume:newVolume];
	[playbackController updateMasterVolume];
}

/*
- (void)volumeUp:(id)sender {
	float newVolume = fminf(volume + VOLUME_STEP, 1.0);
	[self setVolumeUpdatingMaster:newVolume];
}

- (void)volumeDown:(id)sender {
	float newVolume = fmaxf(volume - VOLUME_STEP, 0.0);
	[self setVolumeUpdatingMaster:newVolume];
}
*/
 
- (void)setSong:(Song*)newSong {
	if (newSong != song) {
		[song release];
		song = [newSong retain];
	}
}

- (Song*)song {
	return song;
}

- (NSImage*)dragImage {
	NSString* songDescription = [song description];
	NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSFont systemFontOfSize:[NSFont systemFontSize]] forKey:NSFontAttributeName];
	
	NSImage* image = [[NSImage alloc] initWithSize:[songDescription sizeWithAttributes:attributes]];
	
	[image lockFocus];
	[songDescription drawAtPoint:NSMakePoint(0.0, 0.0) withAttributes:attributes];
	[image unlockFocus];
	
	return [image autorelease];
}

- (IBAction)setVolumeFromSlider:(id)sender {
	[self setVolumeUpdatingMaster:[sender floatValue]];
	
	[playbackController cancelAutoFade];
}

- (float)position {
	return [movie currentTimeInSeconds];
}

- (void)setPosition:(float)newPosition {
	[movie setCurrentTimeInSeconds:scrubPosition];
}

- (void)loadSong:(Song*)newSong {
	[playbackController resetAutoFade];
	
	[self setSong:newSong];
	[playbackController saveLoadedSongs];
	
	moviePlayed = NO;
	userAttentionRequest = -1;
	
	[self loadMovie:[song movie]];
}

- (void)startTimer {
	updateTimer = [[NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL 
													target:self 
												  selector:@selector(update:) 
												  userInfo:nil 
												   repeats:YES] retain];
}

- (void)checkAutoFade:(id)dummy {
//	if (![playbackController autoFadeEnabled]) {
//		return;
//	}
	[autoFadeStartTimer invalidate];
	[autoFadeStartTimer release];
	autoFadeStartTimer = nil;
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	float offset = ([movie durationInSeconds] - [defaults floatForKey:@"FadeOutTime"] - [defaults floatForKey:@"FadeInTime"] - [movie currentTimeInSeconds]);
	if (offset <= 0) {
//		if (![other isPlaying] && [self isPlaying]) {
//			[playbackController startAutoFadeFadingInDeck:other 
//											fadingOutDeck:self 
//												   offset:offset];
//		}
		[playbackController deck:self reachedAutoFadePositionWithOffset:offset];
	} else if ([self isPlaying]) {
		autoFadeStartTimer = [[NSTimer scheduledTimerWithTimeInterval:offset
															   target:self 
															 selector:@selector(checkAutoFade:) 
															 userInfo:nil 
															  repeats:NO] retain];
//		NSLog(@"scheduling timer in %f seconds", offset);
	}
	
}

- (void)stopTimer {
	[updateTimer invalidate];
	[updateTimer release];
	updateTimer = nil;
	[autoFadeStartTimer invalidate];
	[autoFadeStartTimer release];
	autoFadeStartTimer = nil;
}

- (void)stopMovie {
	NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
	
	[defaultCenter removeObserver:self name:nil object:movie];
}

- (void)loadMovie:(QTMovie*)newMovie {
	[self stopMovie];
	
	movie = newMovie;
	[player setMovie:movie];
	[movie setIdling:YES];
	[movie setOutputDevice:activeOutputDevice];
	[self update:nil];
	
	NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
	
	[defaultCenter addObserver:self selector:@selector(volumeDidChange:) name:QTMovieVolumeDidChangeNotification object:movie];
	[defaultCenter addObserver:self selector:@selector(positionDidChange:) name:QTMovieTimeDidChangeNotification object:movie];
	[defaultCenter addObserver:self selector:@selector(movieDidEnd:) name:QTMovieDidEndNotification object:movie];
	[defaultCenter addObserver:self selector:@selector(rateDidChange:) name:QTMovieRateDidChangeNotification object:movie];

//	 NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//	float duration = [movie durationInSeconds];
//	float crossfadeDuration = [defaults boolForKey:@"AutoCrossfade"] ? ([defaults floatForKey:@"FadeOutTime"] + [defaults floatForKey:@"FadeInTime"]) : 0;
//	float warningDuration = [defaults floatForKey:@"AdvanceWarningTime"];
	
	[self updateAdvanceWarning];
}

- (void)updateAdvanceWarning {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	float duration = [movie durationInSeconds];
	float crossfadeDuration = [defaults boolForKey:@"AutoCrossfade"] ? ([defaults floatForKey:@"FadeOutTime"] + [defaults floatForKey:@"FadeInTime"]) : 0;
	float warningDuration = [defaults floatForKey:@"AdvanceWarningTime"];
//	NSLog(@"advance warning for %@ at %f seconds", movie, (duration - crossfadeDuration - warningDuration));
	[positionSlider setMaxValue:duration];
	[positionSlider setWarningValue:(duration - crossfadeDuration - warningDuration)];
	[positionSlider setCriticalValue:duration+1];
}

- (void)update:(id)dummy {
	float currentTime = [movie currentTimeInSeconds];
	float duration = [movie durationInSeconds];
	float remaining = duration - currentTime;
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	float crossfadeDuration = [defaults boolForKey:@"AutoCrossfade"] ? ([defaults floatForKey:@"FadeOutTime"] + [defaults floatForKey:@"FadeInTime"]) : 0;
	float warningDuration = [defaults floatForKey:@"AdvanceWarningTime"];
	if ((remaining < (crossfadeDuration + warningDuration)) && (userAttentionRequest == -1)) {
		userAttentionRequest = [NSApp requestUserAttention:NSCriticalRequest];
//		NSLog(@"userAttentionRequest: %d", userAttentionRequest);
	}
	
	[positionSlider setFloatValue:currentTime];
	[timeElapsed setFloatValue:currentTime];
	[timeRemaining setFloatValue:-remaining];
}

- (QTMovie*)movie {
	return movie;
}

//- (Deck*)deck {
//	return deck;
//}

- (void)startAutoFadeAt:(float)start duration:(float)duration startVolume:(float)startVolume targetVolume:(float)target {
	if ((target == 0.0) && (![self isPlaying])) {
		// no need to fade out an already stopped deck
		return;
	}
	if (!movie) {
		// if no song is loaded, try to load the next one
		if ([[playbackController playlist] count] > 0) {
			[playbackController moveSongWithIndex:0 toDeck:self];
		} else {
			return;
		}
	}
	if (autoFadeTimer != nil) {
		[NSException raise:@"Auto fade already in progress" format:@"start time: %f duration: %f start volume: %f target volume: %f", autoFadeStart, autoFadeDuration, autoFadeStartVolume, autoFadeTargetVolume];
	}
	autoFadeStart = start;
	autoFadeDuration = duration;
	autoFadeStartVolume = startVolume;
	autoFadeTargetVolume = target;
	[self play:nil];
	autoFadeTimer = [[NSTimer scheduledTimerWithTimeInterval:AUTO_FADE_INTERVAL target:self selector:@selector(updateAutoFade:) userInfo:nil repeats:YES] retain];
	[autoFadeTimer fire];
}

- (void)stopAutoFade {
	if (autoFadeTimer != nil) {
		[autoFadeTimer invalidate];
		[autoFadeTimer release];
		autoFadeTimer = nil;
		[playbackController deckFinishedAutoFade:self];
//	} else {
//		NSLog(@"autofade not active");
	}
}

- (void)updateAutoFade:(id)dummy {
//	NSLog(@"deck: %@ currentTime: %f start time: %f duration: %f start volume: %f target volume: %f", self, [movie currentTimeInSeconds], autoFadeStart, autoFadeDuration, autoFadeStartVolume, autoFadeTargetVolume);

	float current = [movie currentTimeInSeconds];
	float vol;
	
	if (current < autoFadeStart) {
		vol = autoFadeStartVolume;
	} else if (current >= autoFadeStart + autoFadeDuration) {
		vol = autoFadeTargetVolume;
		[self stopAutoFade];
//		NSLog(@"stopping autofade");
	} else {
		vol = autoFadeStartVolume + (current - autoFadeStart)/autoFadeDuration*(autoFadeTargetVolume - autoFadeStartVolume);
	}
	
	[self setVolumeUpdatingMaster:vol];
}
/*
- (BOOL)autoFadeIsActive {
	return (autoFadeTimer != nil);
}
*/
- (void)deck:(Deck*)deck receivedRow:(int)rowIndex {
	[playbackController moveSongWithIndex:rowIndex toDeck:self];
}

- (void)deck:(Deck*)deck receivedSong:(Song*)newSong {
	[self loadSong:newSong];
}

- (void)deck:(Deck*)deck receivedFile:(NSString*)file {
	Song* newSong = [[Song alloc] initWithFilename:file];
	[self deck:deck receivedSong:newSong];
	[newSong release];
}

- (void)volumeDidChange:(NSNotification*)notification {
//	QTMovie* movie = (QTMovie*)[notification object];
	
//	[playbackController updateMasterVolume];
}

- (void)positionDidChange:(NSNotification*)notification {
//	QTMovie* movie = (QTMovie*)[notification object];
//	NSLog(@"movie: %@ position: %@", movie, QTStringFromTime([movie currentTime]));
	[self checkAutoFade:nil];
	[self update:nil];
}

- (void)movieDidEnd:(NSNotification*)notification {
//	NSLog(@"movie: %@ did end", [notification object]);
	
	if (autoFadeTimer) {
		[self updateAutoFade:nil];
	}
	if (userAttentionRequest != -1) {
		[NSApp cancelUserAttentionRequest:userAttentionRequest];
		userAttentionRequest = -1;
	}
	[self pause:nil];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AutoLoad"]) {
		[playbackController advanceSongForDeck:self];
	} else {
		[self cue:nil];
	}
}

- (void)rateDidChange:(NSNotification*)notification {
//	QTMovie* movie = (QTMovie*)[notification object];
	if ([self isPlaying]) {
		[self startTimer];
		[self checkAutoFade:nil];
	} else {
		[self stopTimer];
	}
//	NSLog(@"movie: %@ %@", movie, [self isPlaying] ? @"started playing" : @"paused");
}

- (void)setIdling:(BOOL)idling {
	[movie setIdling:idling];
}

- (void)setCueActive:(BOOL)active {
	if (active != cueActive) {
		if (active) {
			[movie setVolume: [[NSUserDefaults standardUserDefaults] floatForKey:@"CueVolume"]];
//			[movie setVolume: [playbackController cueVolume]];
			[eavesdropButton setState:NSOnState];
		} else {
			[movie setVolume: volume];
			[eavesdropButton setState:NSOffState];
		}
	}
	cueActive = active;
	[self updateOutputDevice];
}

- (void)updateOutputDevice {
	AudioDevice* device = cueActive ? [playbackController cueOutputDevice] : [playbackController masterOutputDevice];
	if (device != activeOutputDevice) {
		[activeOutputDevice release];
		[movie setOutputDevice:device];
		activeOutputDevice = [device retain];
	}
}

- (void)cueVolumeChanged:(float)newVolume {
	if (cueActive) {
		[movie setVolume: newVolume];
	}
}

@end
