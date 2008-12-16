//
//  DJController.h
//  SimpleDJ
//
//  Created by Bernhard Bauer on 01.12.07.
//  Copyright 2007 Black Sheep Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//#import <QTKit/QTKit.h>
#import <iMediaBrowser/iMedia.h>

@class DeckController, Song, MySlider, AudioDevice, AudioDeviceList, PlaylistController;

typedef enum {
	AutoFadeInactive, 
	AutoFadeActive, 
	AutoFadeCancelled
} AutoFadeStatus;

@interface DJController : NSObject {
	NSMutableArray* playlist;
	
//	BOOL autoFade;
	AutoFadeStatus autofadeStatus;
	
	float faderPosition;
	float masterVolume;
	
	AudioDevice* masterOutputDevice;
	AudioDevice* cueOutputDevice;
	
	IBOutlet AudioDeviceList* audioDeviceList;
	
	IBOutlet NSArrayController* historyController;
	IBOutlet PlaylistController* playlistController;
	
	IBOutlet DeckController* deck1;
	IBOutlet DeckController* deck2;
	
	IBOutlet NSWindow* playerWindow;
	
	IBOutlet MySlider* crossFader;
	IBOutlet MySlider* volumeSlider;
	
	IBOutlet MySlider* deck1Volume;
	IBOutlet MySlider* deck2Volume;

//	IBOutlet NSTextField* autofadeStatusField;
//	IBOutlet NSButton* autofadeButton;
//	IBOutlet NSProgressIndicator* autofadeProgress;
	IBOutlet NSToolbarItem* autofadeToolbarItem;
	
	IBOutlet NSFormatter* timeFormatter;
	IBOutlet NSTextField* infoField;
	
	iMediaBrowser* browser;
	
	BOOL shutdown;
}

- (NSArray*)playlist;

- (AudioDevice*)masterOutputDevice;
- (void)setMasterOutputDevice:(AudioDevice*)device;
- (AudioDevice*)cueOutputDevice;
- (void)setCueOutputDevice:(AudioDevice*)device;

- (void)loadAudioDevices;

- (void)updateIndividualVolumes;
- (void)updateMasterVolume;

- (void)deck:(DeckController*)fadeOutDeck reachedAutoFadePositionWithOffset:(float)offset;
- (void)deckFinishedAutoFade:(DeckController*)deck;
- (void)startAutoFadeFadingInDeck:(DeckController*)fadeIn fadingOutDeck:(DeckController*)fadeOut offset:(float)autoFadeOffset;
- (void)cancelAutoFade;
- (void)resetAutoFade;

- (void)updateEditedStatus;

- (void)updateAutoFadeStatus;
- (IBAction)startStopAutofade:(id)sender;

- (NSDate*)finishTime;
- (void)updateInfoField:(id)dummy;

- (void)queueSongForDeck:(DeckController*)deck;
- (void)advanceSongForDeck:(DeckController*)deck;
- (void)moveSongWithIndex:(int)index toDeck:(DeckController*)deck;

- (IBAction)showMediaBrowser:(id)sender;
- (IBAction)setCrossfader:(id)sender;
- (IBAction)setMasterVolume:(id)sender;

- (IBAction)loadSongs:(id)sender;

- (void)saveLoadedSongs;

- (BOOL)openDirectory:(NSString *)dirname;
- (BOOL)openAudioFile:(NSString*)filename;
- (BOOL)openPlaylist:(NSString*)filename;
- (BOOL)openFile:(NSString *)filename;

- (NSString*)applicationSupportFolder;
- (NSString*)applicationSupportFile:(NSString*)name;

@end
