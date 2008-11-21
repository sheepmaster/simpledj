//
//  NSWindowController+Toggle.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 30.09.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "NSWindowController+Toggle.h"


@implementation NSWindowController(Toggle)

- (IBAction)toggleWindow:(id)sender {
	NSWindow* window = [self window];
	if ([window isVisible]) {
		[window close];
	} else {
		[self showWindow:sender];
	}
}

@end
