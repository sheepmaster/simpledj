//
//  AudioDeviceList.h
//  SimpleDJ
//
//  Created by Bernhard Bauer on 05.09.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <CoreAudio/CoreAudio.h>

@class AudioDevice;

@interface AudioDeviceList : NSObject {
	NSMutableDictionary* audioDevices;
}

- (void)updateAudioDevices;
- (NSArray*)audioDevices;
- (AudioDevice*)audioDeviceForID:(AudioDeviceID)deviceID;

@end
