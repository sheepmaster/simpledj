//
//  DJController.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 01.12.07.
//  Copyright 2007 Black Sheep Software. All rights reserved.
//

#import "DJController.h"

#import "Deck.h"
#import "DeckController.h"
#import "Song.h"
#import "MySlider.h"
#import "QTMovie+SimpleDJ.h"
#import "NSWindowController+Toggle.h"
#import "AudioDeviceList.h"
#import "PlaylistController.h"
#import "M3UParser.h"

@implementation DJController

// see http://www.codecomments.com/message755849.html

extern void QTSetProcessProperty(UInt32 type, UInt32 creator, size_t size, uint8_t *data);


- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	char *fairplay = "FairPlay";
	QTSetProcessProperty('dmmc', 'play', strlen(fairplay), (uint8_t *)fairplay);
}

- (IBAction)showMediaBrowser:(id)sender {
	browser = [iMediaBrowser sharedBrowserWithDelegate:self supportingBrowserTypes:[NSArray arrayWithObject:@"iMBMusicController"]];
	[browser toggleWindow:self];
//	[browser showMediaBrowser:@"iMBMusicController"];
}

- (BOOL)iMediaBrowser:(iMediaBrowser *)browser willLoadBrowser:(NSString *)browserClassname {
	return YES;
}

- (void)iMediaBrowser:(iMediaBrowser *)browser didLoadBrowser:(NSString *)browserClassname {
	[deck1 setIdling:YES];
	[deck2 setIdling:YES];
}

- (void)iMediaBrowser:(iMediaBrowser *)browser doubleClickedSelectedObjects:(NSArray*)selection {
	NSLog(@"double-clicked: %@", selection);
}

+ (void)initialize {
	NSMutableDictionary* initialValues = [NSMutableDictionary dictionary];
	[initialValues setObject:[NSNumber numberWithFloat:1.0] forKey:@"CueVolume"];
	[initialValues setObject:[NSNumber numberWithFloat:5.0] forKey:@"FadeInTime"];
	[initialValues setObject:[NSNumber numberWithFloat:1.0] forKey:@"FadeOutTime"];
	[initialValues setObject:[NSNumber numberWithFloat:3.0] forKey:@"AdvanceWarningTime"];
	[initialValues setObject:[NSNumber numberWithBool:YES] forKey:@"AutoCrossfade"];
	[initialValues setObject:[NSNumber numberWithBool:YES] forKey:@"AutoLoad"];
//	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValues];
	[[NSUserDefaults standardUserDefaults] registerDefaults:initialValues];
}

- (id)init {
	if (self = [super init]) {
//		[playlist addObject: [[[Song alloc] initWithFilename:@"/Users/bauerb/Documents/projects/cocoa/SimpleDJ/New Soul.mp3"] autorelease]];
//		[playlist addObject: [[[Song alloc] initWithFilename:@"/Users/bauerb/Documents/projects/cocoa/SimpleDJ/Prototypes - Je Ne Te Connais Pas.mp3"] autorelease]];
		id object = [NSKeyedUnarchiver unarchiveObjectWithFile:[self applicationSupportFile:@"playlist"]];
		if (object != nil) {
			playlist = [object retain];
		} else {
			playlist = [[NSMutableArray alloc] init];
		}
		//		audioDeviceList = [[AudioDeviceList alloc] init];
		faderPosition = 0.5;
		masterVolume = 1;
//		autoFade = YES;
		[self resetAutoFade];
	}
	return self;
}

- (void)dealloc {
	[playlist release];
	[masterOutputDevice release];
	[cueOutputDevice release];
//	[audioDeviceList release];
	[super dealloc];
}

- (void)awakeFromNib { 
	[self loadAudioDevices];
	
//	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
//															  forKeyPath:@"values.AutoCrossfade" 
//																 options:NSKeyValueObservingOptionNew
//																 context:nil];
	[audioDeviceList addObserver:self
					  forKeyPath:@"audioDevices"
						 options:NSKeyValueObservingOptionNew
						 context:nil];
	
	id object = [NSKeyedUnarchiver unarchiveObjectWithFile:[self applicationSupportFile:@"history"]];
	if (object != nil) {
		[historyController addObjects:object];
	}

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* filename1 = [defaults stringForKey:@"Deck1Song"];
	NSString* filename2 = [defaults stringForKey:@"Deck2Song"];
	if (filename1 != nil) {
		[deck1 loadSong:[[Song alloc] initWithFilename:filename1]];
	}
	if (filename2 != nil) {
		[deck2 loadSong:[[Song alloc] initWithFilename:filename2]];
	}
	
	[self updateIndividualVolumes];
	
	[crossFader setAltIncrementValue:0.5];
	
	[crossFader setIncreaseValueKeyCode:12];
	[crossFader setDecreaseValueKeyCode:0];
	[deck1Volume setIncreaseValueKeyCode:13];
	[deck1Volume setDecreaseValueKeyCode:1];
	[deck2Volume setIncreaseValueKeyCode:14];
	[deck2Volume setDecreaseValueKeyCode:2];
	[volumeSlider setIncreaseValueKeyCode:15];
	[volumeSlider setDecreaseValueKeyCode:3];
	
	[self updateAutoFadeStatus];
	
	[[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateInfoField:) userInfo:nil repeats:YES] fire];
}

- (void)loadAudioDevices {
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	
	[self setMasterOutputDevice:[audioDeviceList audioDeviceForID:[userDefaults integerForKey:@"MasterOutputDevice"]]];
	[self setCueOutputDevice:[audioDeviceList audioDeviceForID:[userDefaults integerForKey:@"CueOutputDevice"]]];
	
//	NSLog(@"masterOutput: %@ cueOutput: %@", [masterOutputDevice name], [cueOutputDevice name]);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//	NSLog(@"keyPath: %@ of object %@ changed: %@", keyPath, object, change);
//	if ([keyPath isEqualTo:@"values.AutoCrossfade"]) {
//		BOOL newValue = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoCrossfade"];
//		if (newValue && (autofadeStatus == AutoFadeInactive)) {
//			autofadeStatus = AutoFadeWaiting;
//		} else if (!newValue && (autofadeStatus == AutoFadeWaiting)) {
//			autofadeStatus = AutoFadeInactive;
//		}
//	} else
	if ([keyPath isEqualTo:@"audioDevices"]) {
		[self loadAudioDevices];
	}
	[self updateAutoFadeStatus];
}

- (void)deckFinishedAutoFade:(DeckController*)deck {
	if (![deck1 autoFadeActive] && ![deck2 autoFadeActive]) {
		[self resetAutoFade];
	}
	[self updateAutoFadeStatus];
}

- (void)deck:(DeckController*)fadeOutDeck reachedAutoFadePositionWithOffset:(float)offset {
	DeckController* fadeInDeck;
	if (fadeOutDeck == deck1) {
		fadeInDeck = deck2;
	} else if (fadeOutDeck == deck2) {
		fadeInDeck = deck1;
	} else {
		NSLog(@"unknown deck %@", fadeOutDeck);
		return;
	}
	if ((autofadeStatus == AutoFadeInactive) 
		&& [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoCrossfade"] 
		&& ![fadeInDeck isPlaying] 
		&& [fadeOutDeck isPlaying]) {
		[self startAutoFadeFadingInDeck:fadeInDeck 
						  fadingOutDeck:fadeOutDeck 
								 offset:offset];
	}
}

- (void)startAutoFadeFadingInDeck:(DeckController*)fadeIn fadingOutDeck:(DeckController*)fadeOut offset:(float)autoFadeOffset {
	autofadeStatus = AutoFadeActive;

	NSLog(@"starting autofade with offset %f", autoFadeOffset);
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	float fadeInInterval = [defaults floatForKey:@"FadeInTime"];
	float fadeOutInterval = [defaults floatForKey:@"FadeOutTime"];
	float fadeInPosition = [[fadeIn movie] currentTimeInSeconds];
	float fadeOutPosition = [[fadeOut movie] currentTimeInSeconds];
	[fadeIn startAutoFadeAt:(fadeInPosition + autoFadeOffset) 
				   duration:fadeInInterval 
				startVolume:0.0 
			   targetVolume:masterVolume];
	[fadeOut startAutoFadeAt:(fadeOutPosition + autoFadeOffset + fadeInInterval)
			  duration:fadeOutInterval 
		   startVolume:[fadeOut volume] 
		  targetVolume:0.0];
	
	[self updateAutoFadeStatus];
}
/*
- (BOOL)autoFadeEnabled {
	return autoFade;
}
*/
- (void)cancelAutoFade {
//	autoFade = [deck1 stopAutoFade] && [deck2 stopAutoFade];
	[deck1 stopAutoFade];
	[deck2 stopAutoFade];
	if (autofadeStatus == AutoFadeActive) {
		autofadeStatus = AutoFadeCancelled;
	}
	[self updateAutoFadeStatus];
}

- (void)resetAutoFade {
//	autoFade = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoCrossfade"];
//	if ((autofadeStatus == AutoFadeCancelled) || (autofadeStatus == AutoFadeActive)) {
//		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AutoCrossfade"]) {
//			autofadeStatus = AutoFadeWaiting;
//		} else {
//			autofadeStatus = AutoFadeInactive;
//		}
//		[self updateAutoFadeStatus];
//	}
	autofadeStatus = AutoFadeInactive;
	[self updateAutoFadeStatus];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item {
	BOOL enabled = YES;
	if (item == autofadeToolbarItem) {
		[item setLabel:((autofadeStatus == AutoFadeActive) ? @"Stop" : @"Start")];
		[item setImage:[NSImage imageNamed:((autofadeStatus == AutoFadeActive) ? @"StopCrossfade" : @"StartCrossfade")]];
		if (autofadeStatus == AutoFadeCancelled) {
			enabled = NO;
		} else if (autofadeStatus == AutoFadeInactive) {
			int numberOfPlayingDecks = 0;
			if ([deck1 isPlaying]) {
				numberOfPlayingDecks++;
			}
			if ([deck2 isPlaying]) {
				numberOfPlayingDecks++;
			}
			enabled = (numberOfPlayingDecks == 1) && (([deck1 movie] != nil) && ([deck2 movie] != nil));
		}
	}
	return enabled;
}

- (void)updateAutoFadeStatus {
	[autofadeToolbarItem validate];
}

- (IBAction)startStopAutofade:(id)sender {
	if (autofadeStatus == AutoFadeActive) {
		[self cancelAutoFade];
	} else {
		if (([deck1 movie] == nil) || ([deck2 movie] == nil)) {
			NSBeep();
		} else if ([deck1 isPlaying] && ![deck2 isPlaying]) {
			[self startAutoFadeFadingInDeck:deck2 fadingOutDeck:deck1 offset:0];
		} else if ([deck2 isPlaying] && ![deck1 isPlaying]) {
			[self startAutoFadeFadingInDeck:deck1 fadingOutDeck:deck2 offset:0];
		} else {
			NSBeep();
		}
	}
}

- (void)updateEditedStatus {
	[playerWindow setDocumentEdited:([deck1 isPlaying] || [deck2 isPlaying])];
}

- (void)updateInfoField:(id)dummy {
	int count = [playlist count];
	[infoField setStringValue:[NSString stringWithFormat:((count == 1) ? @"%d song, %@ total (ETA: %@)" : @"%d songs, %@ total (ETA: %@)"), 
							   count, 
							   [[NSValueTransformer valueTransformerForName:@"TimeValueTransformer"] transformedValue:[playlistController totalDuration]], 
							   [timeFormatter stringForObjectValue:[self finishTime]]]];
}

- (void)advanceSongForDeck:(DeckController*)deck {
	[deck1 stopAutoFade];
	[deck2 stopAutoFade];
	if ([playlist count] > 0) {
		[self moveSongWithIndex:0 toDeck:deck];
	} else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AutoClearDeck"]) {
		[deck clearMovie:self];
	} else {
		[deck cue:self];
	}
}


- (NSArray*)playlist {
	return playlist;
}

static inline double myAdd(double a, double b, double c) {
	double d = a + b;
	if ((a > 0) && (b > 0)) {
		d -= c;
	}
	return d;
}

- (NSDate*)finishTime {
	NSTimeInterval remainingInPlaylist = [[playlistController totalDuration] floatValue]/1000;
	QTMovie* movie1 = [deck1 movie];
	NSTimeInterval remainingInDeck1 = [movie1 durationInSeconds] - [movie1 currentTimeInSeconds];
	QTMovie* movie2 = [deck2 movie];
	NSTimeInterval remainingInDeck2 = [movie2 durationInSeconds] - [movie2 currentTimeInSeconds];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSTimeInterval crossFadeDuration = [defaults boolForKey:@"AutoCrossfade"] ? ([defaults floatForKey:@"FadeInTime"] + [defaults floatForKey:@"FadeOutTime"]) : 0;
	
	NSTimeInterval remainingTime;
	if ([deck1 isPlaying] && [deck2 isPlaying]) {
		remainingTime = fmax(remainingInDeck1, remainingInDeck2);
	} else {
		remainingTime = myAdd(remainingInDeck1, remainingInDeck2, crossFadeDuration);
	}
	remainingTime = myAdd(remainingTime, remainingInPlaylist, crossFadeDuration);
//	NSLog(@"remaining time: %f", remainingTime);
	NSDate* time = [NSDate dateWithTimeIntervalSinceNow:remainingTime];
//	NSLog(@"ETA: %@", time);
	return time;
}

- (void)moveSongWithIndex:(int)index toDeck:(DeckController*)deck {
	[deck loadSong:[playlist objectAtIndex:index]];
	
	[playlistController removeObjectAtArrangedObjectIndex:index];
}

- (AudioDevice*)masterOutputDevice {
	return masterOutputDevice;
}
- (void)setMasterOutputDevice:(AudioDevice*)device {
	[masterOutputDevice autorelease];
	masterOutputDevice = [device retain];
//	NSLog(@"master output: %@", [masterOutputDevice name]);
	[[NSUserDefaults standardUserDefaults] setInteger:[masterOutputDevice deviceID] forKey:@"MasterOutputDevice"];
	[deck1 updateOutputDevice];
	[deck2 updateOutputDevice];
}
- (AudioDevice*)cueOutputDevice {
	return cueOutputDevice;
}
- (void)setCueOutputDevice:(AudioDevice*)device {
	[cueOutputDevice autorelease];
	cueOutputDevice = [device retain];
//	NSLog(@"cue output: %@", [cueOutputDevice name]);
	[[NSUserDefaults standardUserDefaults] setInteger:[cueOutputDevice deviceID] forKey:@"CueOutputDevice"];
	[deck1 updateOutputDevice];
	[deck2 updateOutputDevice];
}

- (IBAction)setCrossfader:(id)sender {
	faderPosition = [sender floatValue];
//	NSLog(@"faderPosition: %f", faderPosition);
	[self cancelAutoFade];
	[self updateIndividualVolumes];
}

- (IBAction)setMasterVolume:(id)sender {
	masterVolume = [sender floatValue];
//	NSLog(@"masterVolume: %f", masterVolume);
	[self cancelAutoFade];
	[self updateIndividualVolumes];
}

- (void)updateIndividualVolumes {
	float vol1 = ((faderPosition > 0.5) ? 1.0 : (2*faderPosition))*masterVolume;
	float vol2 = ((faderPosition < 0.5) ? 1.0 : (2*(1-faderPosition)))*masterVolume;
	//	NSLog(@"fader: %f master: %f vol1: %f vol2: %f", faderPosition, masterVolume, vol1, vol2);
	
	[deck1 setVolume:vol1];
	[deck2 setVolume:vol2];
}

- (void)updateMasterVolume {
	float vol1 = [deck1 volume];
	float vol2 = [deck2 volume];
	masterVolume = fmaxf(vol1, vol2);
	if (masterVolume > 0) {
		float tmp1 = vol1 / masterVolume;
		float tmp2 = vol2 / masterVolume;
		faderPosition = (tmp1 + 1 - tmp2) / 2;
//		NSLog(@"vol1: %f vol2: %f master: %f tmp1: %f tmp2: %f fader: %f", vol1, vol2, masterVolume, tmp1, tmp2, faderPosition);
	}
//	NSLog(@"masterVolume: %f faderPosition: %f", masterVolume, faderPosition);
	
	[volumeSlider setFloatValue:masterVolume];
	[crossFader setFloatValue:faderPosition];
	
}

- (IBAction)loadSongs:(id)sender {
	NSEvent* theEvent = [NSApp currentEvent];
//	NSLog(@"event: %@", theEvent);
	if (([theEvent type] != NSLeftMouseUp) || ([theEvent clickCount] != 2)) {
		return;
	}
	NSIndexSet* indexes = [(NSTableView*)sender selectedRowIndexes];
	unsigned int i;
	unsigned int offset = 0;
	for (i = [indexes firstIndex]; i != NSNotFound; i = [indexes indexGreaterThanIndex:i]) {
		DeckController* freeDeck = nil;
		if ([deck1 song] == nil) {
			freeDeck = deck1;
		} else if ([deck2 song] == nil) {
			freeDeck = deck2;
		} else {
			NSBeep();
			return;
		}
		[self moveSongWithIndex:i-offset toDeck:freeDeck];
		offset++;
	}
}

- (void)saveLoadedSongs {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[[deck1 song] filename] forKey:@"Deck1Song"];
	[defaults setObject:[[deck2 song] filename] forKey:@"Deck2Song"];
}

- (NSString*)applicationSupportFolder {
	NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	if ([dirs count] == 0) {
		return nil;
	}
	return [[dirs objectAtIndex:0] stringByAppendingPathComponent:@"SimpleDJ"];
}

- (NSString*)applicationSupportFile:(NSString*)name {
	NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	if ([dirs count] == 0) {
		return nil;
	}
	return [[[self applicationSupportFolder] stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"plist"];
}

- (BOOL)openDirectory:(NSString *)dirname {
	NSError* error;
	NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirname error:&error];
	if (contents == nil) {
		NSLog(@"error reading directory %@: %@", dirname, error);
		return NO;
	}
	for (NSString* file in contents) {
		[self openFile:[dirname stringByAppendingPathComponent:file]];
	}
	return YES;
}

- (BOOL)openAudioFile:(NSString*)filename {
	Song* song = [[Song alloc] initWithFilename:filename];
	if (!song) {
		return NO;
	}
	if ([deck1 song] == nil) {
		[deck1 loadSong:song];
	} else if ([deck2 song] == nil) {
		[deck2 loadSong:song];
	} else {
		[playlistController addObject:song];
	}
	[NSApp activateIgnoringOtherApps:NO];
	return YES;
}

- (BOOL)openFile:(NSString*)filename {
	NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
	NSError* error;
	NSString* type = [workspace typeOfFile:filename error:&error];
	if (!type) {
		NSLog(@"error getting type of %@: %@", filename, error);
		return NO;
	}
	if ([workspace type:type conformsToType:@"public.folder"]) {
		[self openDirectory:filename];
	} else if ([workspace type:type conformsToType:@"public.audio"]) {
		return [self openAudioFile:filename];
	} else {
		return NO;
	}
	return YES;
}

- (BOOL)openPlaylist:(NSString*)filename {
	NSArray* files = [M3UParser filenamesInM3UFile:filename];
	if (!files) {
		return NO;
	}
	for (NSString* f in files) {
		[self openFile:f];
	}
	return YES;
}

- (BOOL)application:(NSApplication *)app openFile:(NSString *)filename {
	return [self openFile:filename] || [self openPlaylist:filename];
}

- (BOOL)windowShouldClose:(id)sender {
	if ([deck1 isPlaying] || [deck2 isPlaying]) {
		NSAlert* alert = [NSAlert alertWithMessageText:@"It appears there is still music playing. Do you want to stop playback and quit?" 
										 defaultButton:@"Quit" 
									   alternateButton:@"Cancel" 
										   otherButton:nil 
							 informativeTextWithFormat:@"If you don't want to stop playback, just hit Cancel."];
		[alert beginSheetModalForWindow:playerWindow
						  modalDelegate:self 
						 didEndSelector:@selector(alertSheetDidEnd:returnCode:contextInfo:) 
							contextInfo:sender];
		//		return [alert runModal];
		
		return NO;
	} else {
		return YES;
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)app {
	if (shutdown || [self windowShouldClose:NSApp]) {
		return NSTerminateNow;
	} else {
		return NSTerminateLater;
	}
}

- (void)alertSheetDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (contextInfo == NSApp) {
		[NSApp replyToApplicationShouldTerminate:(returnCode == NSAlertDefaultReturn)];
	} else {
		if (returnCode == NSAlertDefaultReturn) {
			[(NSWindow*)contextInfo close];
		}
	}
}

- (void)windowWillClose:(id)window {
	shutdown = YES;
	[NSApp terminate:self];
}

//- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
//	return YES;
//}

- (void)applicationWillTerminate:(NSNotification*)dummy {
//	NSLog(@"muuh");
	BOOL isDir;
	NSFileManager* fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:[self applicationSupportFolder] isDirectory:&isDir]) {
		isDir = [fm createDirectoryAtPath:[self applicationSupportFolder] attributes:nil];
	}
	if (isDir) {
		[NSKeyedArchiver archiveRootObject:playlist toFile:[self applicationSupportFile:@"playlist"]];
		[NSKeyedArchiver archiveRootObject:[historyController arrangedObjects] toFile:[self applicationSupportFile:@"history"]];
	} else {
		NSLog(@"Couldn't create %@", [self applicationSupportFolder]);
	}
}

@end
