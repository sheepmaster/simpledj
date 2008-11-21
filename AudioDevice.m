//
//  AudioDevice.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 05.09.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "AudioDevice.h"


@implementation AudioDevice

- (id)initWithID:(AudioDeviceID)newDeviceID {
	char buf[64];
	UInt32 maxlen = sizeof(buf);
	verify_noerr(AudioDeviceGetProperty(newDeviceID, 0, false, kAudioDevicePropertyDeviceName, &maxlen, buf));

	return [self initWithName:[NSString stringWithCString:buf encoding:NSASCIIStringEncoding] ID:newDeviceID];
}

- (id)initWithName:(NSString*)newName ID:(AudioDeviceID)newDeviceID {
	if (self = [super init]) {
		name = [newName copy];
		deviceID = newDeviceID;
	}
	return self;
}

- (void)dealloc {
	[name release];
	[super dealloc];
}

- (NSString*)name {
	return name;
}

- (AudioDeviceID)deviceID {
	return deviceID;
}

- (int)numberOfChannels {
	OSStatus err;
	UInt32 propSize;
	int result = 0;

	err = AudioDeviceGetPropertyInfo(deviceID, 0, false, kAudioDevicePropertyStreamConfiguration, &propSize, NULL);
	if (err) return 0;

	AudioBufferList *buflist = (AudioBufferList *)malloc(propSize);
	err = AudioDeviceGetProperty(deviceID, 0, false, kAudioDevicePropertyStreamConfiguration, &propSize, buflist);
	if (!err) {
		UInt32 i;
		for (i = 0; i < buflist->mNumberBuffers; ++i) {
			result += buflist->mBuffers[i].mNumberChannels;
		}
	}
	free(buflist);
	return result;
}

- (NSString*)deviceUID {
	CFStringRef deviceUID = NULL;
	UInt32 dataSize = sizeof(deviceUID);
	verify_noerr(AudioDeviceGetProperty(deviceID, /*channel*/ 0, /*isInput*/ false, kAudioDevicePropertyDeviceUID, &dataSize, &deviceUID));
	return [(NSObject *)deviceUID autorelease];
}

@end
