//
//  Song.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 01.12.07.
//  Copyright 2007 Black Sheep Software. All rights reserved.
//

#import "Song.h"
#import "MetadataUtility.h"
#import <QTKit/QTMovie.h>

static const NSString* TITLE = @"kMDItemTitle";
static const NSString* AUTHORS = @"kMDItemAuthors";
static const NSString* DURATION = @"kMDItemDurationSeconds";

NSString* SongsType = @"BSSSSongsType";

@implementation Song

- (id)initWithURL:(NSURL*)theURL filename:(NSString*)theFilename {
	if (self = [super init]) {
		filename = [theFilename copy];
		url = [theURL retain];
		
		MetadataUtility* mdu = [MetadataUtility sharedMetadataUtility];
		
		NSDictionary* metadata = [mdu getMetadataForFile:filename];
		
//		NSLog(@"metadata: %@", metadata);
		
		if (metadata) {
			title = [[metadata objectForKey:TITLE] retain];
			artist = [[[metadata objectForKey:AUTHORS] objectAtIndex:0] retain]; 
			NSNumber* d = [metadata objectForKey:DURATION];
			duration = [[NSNumber alloc] initWithFloat:[d floatValue]*1000];
			
//			NSLog(@"title: %@ artist: %@ duration: %@", title, artist, duration);
		} else {
			[self release];
			self = nil;
		}
		
	}
	return self;
}

- (id)initWithFilename:(NSString*)theFilename {
	return [self initWithURL:[NSURL fileURLWithPath:theFilename isDirectory:NO] filename:theFilename];
}

- (id)initWithURL:(NSURL*)theURL {
	return [self initWithURL:theURL filename:[theURL path]];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if ([coder allowsKeyedCoding] ) {
        [coder encodeObject:url forKey:@"SDURL"];
        [coder encodeObject:filename forKey:@"SDFilename"];
        [coder encodeObject:artist forKey:@"SDArtist"];
        [coder encodeObject:title forKey:@"SDTitle"];
        [coder encodeObject:duration forKey:@"SDDuration"];
        [coder encodeObject:datePlayed forKey:@"SDDatePlayed"];
    } else {
        [coder encodeObject:url];
        [coder encodeObject:filename];
        [coder encodeObject:artist];
        [coder encodeObject:title];
        [coder encodeObject:duration];
		[coder encodeObject:datePlayed];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ([coder allowsKeyedCoding] ) {
        // Can decode keys in any order
        url = [[coder decodeObjectForKey:@"SDURL"] retain];
        filename = [[coder decodeObjectForKey:@"SDFilename"] retain];
        artist = [[coder decodeObjectForKey:@"SDArtist"] retain];
        title = [[coder decodeObjectForKey:@"SDTitle"] retain];
        duration = [[coder decodeObjectForKey:@"SDDuration"] retain];
		datePlayed = [[coder decodeObjectForKey:@"SDDatePlayed"] retain];
    } else {
        // Must decode keys in same order as encodeWithCoder:
        url = [[coder decodeObject] retain];
        filename = [[coder decodeObject] retain];
        artist = [[coder decodeObject] retain];
        title = [[coder decodeObject] retain];
        duration = [[coder decodeObject] retain];
        datePlayed = [[coder decodeObject] retain];
    }
    return self;
}

- (NSString*)filename {
	return filename;
}

- (NSURL*)url {
	return url;
}

- (NSString*)title {
	return title;
}

- (NSString*)artist {
	return artist;
}

- (NSNumber*)duration {
	return duration;
}

- (NSDate*)datePlayed {
	return datePlayed;
}
- (void)setDatePlayed:(NSDate*)date {
	if (date == nil) {
		date = [NSDate date];
	}
	[datePlayed autorelease];
	datePlayed = [date retain];
}

- (NSString*)description {
	if (artist) {
		return [NSString stringWithFormat:@"%@ - %@", artist, title];
	} else {
		return title;
	}
}

- (void)dealloc {
	[url release];
	[filename release];
	[artist release];
	[duration release];
	[title release];
	[movie release];
	[super dealloc];
}

- (QTMovie*)movie {
	if (movie == nil) {
		NSError* error = nil;
		
		movie = [[QTMovie movieWithFile:filename error:&error] retain];
		if (!movie) {
			NSLog(@"error loading \"%@\": %@", filename, error);
		}
	}
	return movie;
}

@end