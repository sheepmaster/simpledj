//
//  AudioDevice.h
//  SimpleDJ
//
//  Created by Bernhard Bauer on 05.09.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <CoreAudio/CoreAudio.h>


@interface AudioDevice : NSObject {
	NSString* name;
	AudioDeviceID deviceID;
}

- (id)initWithName:(NSString*)newName ID:(AudioDeviceID)newDeviceID;
- (id)initWithID:(AudioDeviceID)newDeviceID;

- (NSString*)name;
- (AudioDeviceID)deviceID;

- (int)numberOfChannels;
- (NSString*)deviceUID;

@end
