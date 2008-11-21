//
//  DeckController.h
//  SimpleDJ
//
//  Created by Bernhard Bauer on 13.07.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

@class Deck;
@class DJController;
@class Song;
@class AudioDevice;

@interface DeckController : NSObject {
	IOPMAssertionID assertionID;
	
	NSInteger userAttentionRequest;
	
	BOOL moviePlayed;
	
	QTMovie* movie;
	Song* song;
		
	NSTimer* updateTimer;
	
	float cuePosition;
	float scrubPosition;
		
	float autoFadeStart;
	float autoFadeDuration;
	float autoFadeTargetVolume;
	float autoFadeStartVolume;
	NSTimer* autoFadeTimer;
	NSTimer* autoFadeStartTimer;
	
	float volume;
	AudioDevice* activeOutputDevice;
	BOOL cueActive;

	IBOutlet NSArrayController* historyController;
	IBOutlet DeckController* other;
	IBOutlet DJController* playbackController;
	
//	IBOutlet Deck* deck;
	
	IBOutlet QTMovieView* player;
	
	IBOutlet NSSlider* volumeSlider;
	
	IBOutlet NSLevelIndicator* positionSlider;
	
	IBOutlet NSTextField* timeElapsed;
	IBOutlet NSTextField* timeRemaining;
	
	IBOutlet NSButton* playPauseButton;
	IBOutlet NSButton* eavesdropButton;
}

- (IBAction)cue:(id)sender;
- (IBAction)skip:(id)sender;
- (IBAction)scrub:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)eavesdrop:(id)sender;
- (IBAction)setVolumeFromSlider:(id)sender;
- (IBAction)clearMovie:(id)sender;

- (float)position;
- (void)setPosition:(float)newPosition;

- (float)volume;
- (void)setVolume:(float)newVolume;

- (BOOL)isPlaying;
- (BOOL)autoFadeActive;

- (void)setVolumeUpdatingMaster:(float)newVolume;

- (void)setSong:(Song*)newSong;
- (Song*)song;

- (NSImage*)dragImage;

- (void)stopMovie;
- (void)loadMovie:(QTMovie*)newMovie;
- (void)loadSong:(Song*)newSong;

- (void)startTimer;
- (void)stopTimer;

- (QTMovie*)movie;
//- (Deck*)deck;

- (void)deck:(Deck*)deck receivedRow:(int)rowIndex;
- (void)deck:(Deck*)deck receivedSong:(Song*)newSong;
- (void)deck:(Deck*)deck receivedFile:(NSString*)file;

- (void)checkAutoFade:(id)dummy;
- (void)startAutoFadeAt:(float)start duration:(float)duration startVolume:(float)startVolume targetVolume:(float)target;
- (void)stopAutoFade;
- (void)updateAutoFade:(id)dummy;

- (void)update:(id)sender;

- (void)updateAdvanceWarning;

- (void)setIdling:(BOOL)idling;

- (void)setCueActive:(BOOL)active;
- (void)updateOutputDevice;

- (void)cueVolumeChanged:(float)newVolume;

@end
