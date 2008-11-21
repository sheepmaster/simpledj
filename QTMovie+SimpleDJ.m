//
//  QTMovie+SimpleDJ.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 18.07.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "QTMovie+SimpleDJ.h"

#import "AudioDevice.h"

@implementation QTMovie(SimpleDJ)

- (float)currentTimeInSeconds {
	QTTime currentTime = [self currentTime];
	return (float)currentTime.timeValue/currentTime.timeScale;
}

- (void)setCurrentTimeInSeconds:(float)time {
	long timeScale = [[self attributeForKey:QTMovieTimeScaleAttribute] longValue];
	long timeValue = (long)(time * timeScale);
	
	[self setCurrentTime:QTMakeTime(timeValue, timeScale)];
}

- (void)setOutputDevice:(AudioDevice*)device {
	QTAudioContextRef audioContext = NULL;
	verify_noerr(QTAudioContextCreateForAudioDevice(kCFAllocatorDefault, (CFStringRef)[device deviceUID], /*options*/ NULL, &audioContext));
	
//	float savedRate = [self rate];
//	[self setRate:0.0];
	verify_noerr(SetMovieAudioContext([self quickTimeMovie], audioContext));
//	[self setRate:savedRate];
	
	QTAudioContextRelease(audioContext);
}

@end
