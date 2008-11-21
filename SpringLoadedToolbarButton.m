//
//  SpringLoadedButton.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 08.09.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "SpringLoadedToolbarButton.h"

#define SPRINGLOAD_INTERVAL 1.0

@implementation SpringLoadedToolbarButton

- (void)dealloc {
	[activationTimer release];
	[super dealloc];
}

- (void)activate:(NSTimer*)timer {
	[self performClick:timer];
	
	activationTimer = nil;
//	[self setState:NSOnState];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
//	NSLog(@"draggingEntered");
	
	NSDrawer* target = [self target];
	if ([target state] == NSDrawerClosedState) {
		activationTimer = [NSTimer scheduledTimerWithTimeInterval:SPRINGLOAD_INTERVAL 
														   target:self 
														 selector:@selector(activate:) 
														 userInfo:nil 
														  repeats:NO];
		
//		[[self window] makeFirstResponder:self];
		[self highlight:YES];
//		return NSDragOperationCopy;
	}
	return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	[activationTimer invalidate];
	activationTimer = nil;
	[self highlight:NO];
//	NSLog(@"draggingExited");
}

@end
