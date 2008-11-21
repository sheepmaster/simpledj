//
//  PlaylistToolbarItem.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 16.09.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "PlaylistToolbarItem.h"

#import "SpringLoadedToolbarButton.h"

#import "PlaylistController.h"
#import "Song.h"
#import "NSPasteboard+SimpleDJ.h"

@implementation PlaylistToolbarItem

- (id)initWithItemIdentifier:(NSString*)identifier {
//	NSLog(@"identifier: %@", identifier);
	if (self = [super initWithItemIdentifier:identifier]) {
		SpringLoadedToolbarButton* button = [[SpringLoadedToolbarButton alloc] initWithItem:self];
//		[button setButtonType:NSToggleButton];
		[self setView:button];
		[button registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, SongsType, AIiTunesTrackPboardType, nil]];
	}
	return self;
}

@end
