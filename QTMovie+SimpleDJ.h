//
//  QTMovie+SimpleDJ.h
//  SimpleDJ
//
//  Created by Bernhard Bauer on 18.07.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@class AudioDevice;

@interface QTMovie(SimpleDJ)

- (float)currentTimeInSeconds;

- (void)setCurrentTimeInSeconds:(float)time;

- (void)setOutputDevice:(AudioDevice*)device;

@end
