//
//  NSPasteboard+SimpleDJ.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 27.10.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "NSPasteboard+SimpleDJ.h"


@implementation NSPasteboard(SimpleDJ)

- (NSArray *)filenamesFromITunesDragPasteboard {
	NSDictionary* dict = [self propertyListForType:AIiTunesTrackPboardType];
//	NSLog(@"dict: %@", dict);
	if (!dict) {
		return nil;
	}
	NSMutableArray* filenames = [NSMutableArray arrayWithCapacity:[dict count]];
	NSDictionary* tracks = [dict objectForKey:@"Tracks"];
	NSArray* trackIDs = [[[dict objectForKey:@"Playlists"] objectAtIndex:0] valueForKeyPath: @"Playlist Items.Track ID"];
	for (NSNumber* trackID in trackIDs) {
//		NSLog(@"track ID: %@", trackID);
		[filenames addObject: [[NSURL URLWithString:[[tracks objectForKey:[trackID stringValue]] objectForKey:@"Location"]] path]];
	}
//	NSLog(@"filenames: %@", filenames);
	return filenames;
}

@end
