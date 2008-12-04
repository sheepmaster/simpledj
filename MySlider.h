//
//  MySlider.h
//  SimpleDJ
//
//  Created by Bernhard Bauer on 30.07.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MySlider : NSSlider {
	unsigned short increaseValueKeyCode;
	unsigned short decreaseValueKeyCode;
	
	NSTimeInterval normalMoveTime;
	NSTimeInterval fastMoveTime;
	
	NSTimer* moveTimer;
	NSDate* moveStartDate;
	float moveDirection;
	float moveVelocity;
	
	unsigned short activeKey;
}

- (unsigned short)increaseValueKeyCode;
- (void)setIncreaseValueKeyCode:(unsigned short)newKeyCode;
- (unsigned short)decreaseValueKeyCode;
- (void)setDecreaseValueKeyCode:(unsigned short)newKeyCode;

- (NSTimeInterval)normalMoveTime;
- (void)setNormalMoveTime:(NSTimeInterval)newTime;
- (NSTimeInterval)fastMoveTime;
- (void)setFastMoveTime:(NSTimeInterval)newTime;

- (void)moveTo:(float)newValue;

- (void)moveSlider:(NSEvent*)theEvent;
- (void)stop;
- (BOOL)setVelocity:(NSEvent*)theEvent;
- (void)updatePosition:(id)dummy;
- (void)_keyUp:(NSNotification*)n;
- (void)_flagsChanged:(NSNotification*)n;
@end
