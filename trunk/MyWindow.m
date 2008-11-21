//
//  MyWindow.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 19.08.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "MyWindow.h"

NSString* KeyUpNotification = @"KeyUpNotification";
NSString* FlagsChangedNotification = @"FlagsChangedNotification";

@implementation MyWindow

- (NSImage*)backgroundImage {
	NSSize size = [self frame].size;
	NSImage* image = [[NSImage alloc] initWithSize:size];
	NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0] 
														 endingColor:[NSColor colorWithCalibratedWhite:0.82 alpha:1.0]];
	[image lockFocus];
	[gradient drawInRect:NSMakeRect(0, 0, size.width, size.height) angle:270.0];
	[image unlockFocus];
	
	[gradient release];
	return [image autorelease];
}

- (void)awakeFromNib {
	[self setBackgroundColor:[NSColor colorWithPatternImage:[self backgroundImage]]];
}

- (void)keyUp:(NSEvent *)theEvent {
//	NSLog(@"window: %@ event: %@", self, theEvent);
	[[NSNotificationCenter defaultCenter] postNotificationName:KeyUpNotification 
														object:[NSNumber numberWithUnsignedShort:[theEvent keyCode]]
													  userInfo:[NSDictionary dictionaryWithObject:theEvent forKey:@"Event"]];
	[super keyUp:theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent {
//	NSLog(@"window: %@ event: %@", self, theEvent);
	[[NSNotificationCenter defaultCenter] postNotificationName:FlagsChangedNotification 
														object:nil
													  userInfo:[NSDictionary dictionaryWithObject:theEvent forKey:@"Event"]];
	[super flagsChanged:theEvent];
}

@end
