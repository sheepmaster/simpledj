//
//  MySlider.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 30.07.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "MySlider.h"

#import "MyWindow.h"

#define ACTION_INTERVAL (1.0/30)

#define DEFAULT_NORMAL_MOVE_TIME 2.0
#define DEFAULT_FAST_MOVE_TIME 0.5

#define SCROLL_WHEEL_NUDGE 0.02

@implementation MySlider
/*
- (id)initWithFrame:(NSRect)rect {
	if (self = [super initWithFrame:rect]) {
		increaseValueKeyCode = -1;
		decreaseValueKeyCode = -1;
	}
//	NSLog(@"initializing new Slider %@", self);
	return self;
}
*/

- (void)awakeFromNib {
	normalMoveTime = DEFAULT_NORMAL_MOVE_TIME;
	fastMoveTime = DEFAULT_FAST_MOVE_TIME;
}

- (unsigned short)increaseValueKeyCode {
	return increaseValueKeyCode;
}
- (void)setIncreaseValueKeyCode:(unsigned short)newKeyCode {
	increaseValueKeyCode = newKeyCode;
}

- (unsigned short)decreaseValueKeyCode {
	return decreaseValueKeyCode;
}
- (void)setDecreaseValueKeyCode:(unsigned short)newKeyCode {
	decreaseValueKeyCode = newKeyCode;
}

- (NSTimeInterval)normalMoveTime {
	return normalMoveTime;
}
- (void)setNormalMoveTime:(NSTimeInterval)newTime {
	normalMoveTime = newTime;
}

- (NSTimeInterval)fastMoveTime {
	return fastMoveTime;
}
- (void)setFastMoveTime:(NSTimeInterval)newTime {
	fastMoveTime = newTime;
}

/*
- (SEL)actionForEvent:(NSEvent *)theEvent {
	if (([theEvent type] == NSKeyDown) && (([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask & ~(NSShiftKeyMask | NSAlternateKeyMask)) == 0)) {
		unsigned short keyCode = [theEvent keyCode];
		if (keyCode == volumeUpKeyCode) {
			return @selector(volumeUp:);
		} else if (keyCode == volumeDownKeyCode) {
			return @selector(volumeDown:);
		}
	}
	return nil;
}
*/

/*
- (void)moveSlider:(NSEvent*)theEvent {
	if ([theEvent isARepeat]) {
		return;
	}
	

	
	BOOL done = NO;
	
	NSDate* date = [NSDate date];
//	NSTimeInterval timestamp = [theEvent timestamp];
	
	float delta = ([theEvent keyCode] == increaseValueKeyCode) ? 1 : -1;
	
	float min = [self minValue];
	float max = [self maxValue];
	float range = max - min;
	
	NSUInteger flags = [theEvent modifierFlags];
	if (flags & NSShiftKeyMask) {
		[self setFloatValue:((delta > 0) ? [self maxValue] : [self minValue])];
		NSLog(@"shift pressed");
		return;
	}
	
	NSTimeInterval moveTime = (flags & NSAlternateKeyMask) ? fastMoveTime : normalMoveTime;
	
	NSLog(@"<<<<<<<<");
	
//	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(muuh:) userInfo:nil repeats:YES];
	
	[NSEvent startPeriodicEventsAfterDelay:0.0 withPeriod:ACTION_INTERVAL];
	while (!done) {
		NSEvent* trackingEvent = [NSApp nextEventMatchingMask: NSPeriodicMask | NSKeyUpMask | NSFlagsChangedMask
//		NSEvent* trackingEvent = [NSApp nextEventMatchingMask: NSKeyUpMask
													untilDate: [NSDate distantFuture]
													   inMode: NSDefaultRunLoopMode
													  dequeue: YES];
		switch([trackingEvent type]) {
			case NSKeyUp:
				done = YES;
				break;
			case NSPeriodic: {
//				NSTimeInterval newTimestamp = [trackingEvent timestamp];
				NSDate* newDate = [NSDate date];
				float newValue = [self floatValue] + delta * ([newDate timeIntervalSinceDate:date]) / moveTime * range;
				NSLog(@"new time: %@ oldTime: %@ new value: %f", newDate, date, newValue);
				if (newValue >= max) {
					newValue = max;
					done = YES;
				}
				if (newValue <= min) {
					newValue = min;
					done = YES;
				}
				[self setFloatValue:newValue];
//				timestamp = newTimestamp;
				date = newDate;
				break;
			}
			default:
				NSLog(@"unknown event %@", trackingEvent);
		}
	}
	[NSEvent stopPeriodicEvents];
	NSLog(@">>>>>>>>");
*/
	
- (void)moveSlider:(NSEvent*)theEvent {
	if ([theEvent isARepeat]) {
		return;
	}
	moveDirection = ([theEvent keyCode] == increaseValueKeyCode) ? 1 : -1;
	activeKey = [theEvent keyCode];
	
	if ([self setVelocity:theEvent] || moveTimer) {
		return;
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyUp:) name:KeyUpNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_flagsChanged:) name:FlagsChangedNotification object:nil];
		
	moveTimer = [[NSTimer scheduledTimerWithTimeInterval:ACTION_INTERVAL 
												  target:self 
												selector:@selector(updatePosition:) 
												userInfo:nil 
												 repeats:YES] retain];
	moveStartDate = [[NSDate alloc] init];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
//	NSLog(@"Deck %@ performKeyEquivalent: %@", self, theEvent);
	if (([theEvent type] == NSKeyDown) && (([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask & ~(NSShiftKeyMask | NSAlternateKeyMask)) == 0)) {
		unsigned short keyCode = [theEvent keyCode];
		if (keyCode == increaseValueKeyCode || keyCode == decreaseValueKeyCode) {
			[self moveSlider:theEvent];
//			[NSThread detachNewThreadSelector:@selector(watchForKeyUp:) toTarget:self withObject:theEvent];
			[[self window] makeFirstResponder:self];
			return YES;
		}
	}
	return NO;
}

- (void)mouseDown:(NSEvent*)theEvent {
	BOOL allowsTickMarkValuesOnly = [self allowsTickMarkValuesOnly];
	if ([theEvent modifierFlags] & NSShiftKeyMask) {
		[self setAllowsTickMarkValuesOnly:YES];
	}
	[super mouseDown:theEvent];
	[self setAllowsTickMarkValuesOnly:allowsTickMarkValuesOnly];
}

- (void)scrollWheel:(NSEvent*)theEvent {
	float value = [self floatValue]+[theEvent deltaY]*SCROLL_WHEEL_NUDGE;
	[self moveTo:value];
}

- (void)moveTo:(float)newValue {
	[self setFloatValue:newValue];
	[self performClick:nil];
}

- (void)_keyUp:(NSNotification*)n {
	NSEvent* theEvent = [[n userInfo] valueForKey:@"Event"];
//	NSLog(@"MySlider: %@ keyUp: %@", self, n);
	if ([theEvent keyCode] == activeKey) {
		[self updatePosition:nil];
		[self stop];
	}
}


- (void)stop {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:KeyUpNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:FlagsChangedNotification object:nil];
	[moveTimer invalidate];
	[moveTimer release];
	moveTimer = nil;
	activeKey = -1;
}

- (BOOL)setVelocity:(NSEvent*)theEvent {
	float min = [self minValue];
	float max = [self maxValue];
	NSUInteger flags = [theEvent modifierFlags];
	if (flags & NSShiftKeyMask) {
		[self moveTo:((moveDirection > 0) ? max : min)];
		return YES;
	}
	
	NSTimeInterval moveTime = (flags & NSAlternateKeyMask) ? fastMoveTime : normalMoveTime;
	moveVelocity = moveDirection / moveTime * (max - min);
	return NO;
}

- (void)_flagsChanged:(NSNotification*)n {
	if ([self setVelocity:[[n userInfo] objectForKey:@"Event"]]) {
		[self stop];
	}
}

- (void)updatePosition:(id)dummy {
	float min = [self minValue];
	float max = [self maxValue];
	NSDate* newDate = [[NSDate alloc] init];
	float newValue = [self floatValue] + moveVelocity * ([newDate timeIntervalSinceDate:moveStartDate]);
//	NSLog(@"new time: %@ oldTime: %@ new value: %f", newDate, moveStartDate, newValue);
	if (newValue >= max) {
		newValue = max;
		[self stop];
	}
	if (newValue <= min) {
		newValue = min;
		[self stop];
	}
	[self moveTo:newValue];
	[moveStartDate release];
	moveStartDate = newDate;
}

/*
- (void)setAction:(SEL)newAction {
	if (action == newAction) {
		return;
	}
	action = newAction;
	if (action == nil) {
		[actionTimer invalidate];
		[actionTimer release];
		actionTimer = nil;
	} else {
		actionTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:target selector:action userInfo:nil repeats:YES] retain];
		[actionTimer fire];
	}
}

- (void)keyUp:(NSEvent*)event {
	NSLog(@"Deck %@ keyUp: %@", self, event);
	unsigned short keyCode = [event keyCode];
	if (keyCode == volumeUpKeyCode || keyCode == volumeDownKeyCode) {
		[self setAction:nil];
	} else {
		[super keyUp:event];
	}
}
*/

@end
