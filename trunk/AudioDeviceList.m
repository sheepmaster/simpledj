//
//  AudioDeviceList.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 05.09.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "AudioDeviceList.h"

#import "AudioDevice.h"

OSStatus audioDevicesChanged(AudioHardwarePropertyID propertyID, void *clientData) {
	AudioDeviceList* list = (AudioDeviceList*)clientData;
	
	[list performSelectorOnMainThread:@selector(updateAudioDevices) withObject:nil waitUntilDone:NO];
	
	return noErr;
}

@implementation AudioDeviceList

- (id)init {
	if (self = [super init]) {
		audioDevices = [[NSMutableDictionary alloc] init];
		[self updateAudioDevices];
		AudioHardwareAddPropertyListener(kAudioHardwarePropertyDevices, audioDevicesChanged, self);
	}
	return self;
}

- (void)updateAudioDevices {
	[self willChangeValueForKey:@"audioDevices"];
	
	NSDictionary* oldDevices = audioDevices;
	audioDevices = [[NSMutableDictionary alloc] init];
	
	UInt32 propsize;
	
	verify_noerr(AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propsize, NULL));
	AudioDeviceID* devids = (AudioDeviceID*)malloc(propsize);
	int nDevices = propsize / sizeof(AudioDeviceID);	
	verify_noerr(AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propsize, devids));
	
	int i;
	for (i = 0; i < nDevices; ++i) {
		NSNumber* devID = [NSNumber numberWithUnsignedInt:devids[i]];
		AudioDevice* dev = [oldDevices objectForKey:devID];
		if (dev == nil) {
			dev = [[[AudioDevice alloc] initWithID:devids[i]] autorelease];
		}
		
		if ([dev numberOfChannels] > 0) {
//			NSLog(@"id: %u name: %@", devids[i], [dev name]);
			[audioDevices setObject:dev forKey:devID];
		}
		

//		AudioDevice dev(devids[i], mInputs);
//		if (dev.CountChannels() > 0) {
//			Device d;
//			
//			d.mID = devids[i];
//			dev.GetName(d.mName, sizeof(d.mName));
//			mDevices.push_back(d);
//		}
	}
		
	free(devids);
	//	AudioDeviceID devID = 0;
//	AudioDevice* dev = [[[AudioDevice alloc] initWithName:@"Muuh" ID:devID] autorelease];
//	[audioDevices addObject:dev];
	[oldDevices release];
	
	[self didChangeValueForKey:@"audioDevices"];
}

- (AudioDeviceID)systemOutputDevice {
	AudioDeviceID systemOutputDevice = 0;
	UInt32 dataSize = sizeof(systemOutputDevice);
	verify_noerr(AudioHardwareGetProperty(kAudioHardwarePropertyDefaultSystemOutputDevice, &dataSize, &systemOutputDevice));
	return systemOutputDevice;
}

- (NSArray*)audioDevices {
	return [audioDevices allValues];
}

- (AudioDevice*)audioDeviceForID:(AudioDeviceID)deviceID {
	AudioDevice* device = [audioDevices objectForKey:[NSNumber numberWithUnsignedInt:deviceID]];
	if (device != nil) {
		return device;
	} else {
		return [audioDevices objectForKey:[NSNumber numberWithUnsignedInt:[self systemOutputDevice]]];
	}
}

- (void)dealloc {
	[audioDevices release];
	[super dealloc];
}

@end
