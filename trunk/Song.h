//
//  Song.h
//  SimpleDJ
//
//  Created by Bernhard Bauer on 01.12.07.
//  Copyright 2007 Black Sheep Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QTMovie;

extern NSString* SongsType;

@interface Song : NSObject<NSCoding> {
	NSString* title;
	NSString* artist;
	NSNumber* duration;
	
	NSDate* datePlayed;
	
	NSString* filename;
	NSURL* url;
	
	QTMovie* movie;
}

- (id)initWithFilename:(NSString*)theFilename;
- (id)initWithURL:(NSURL*)theURL;

- (NSURL*)url;
- (NSString*)filename;

- (NSString*)title;
- (NSString*)artist;
- (NSNumber*)duration;

- (NSDate*)datePlayed;
- (void)setDatePlayed:(NSDate*)date;

- (QTMovie*)movie;

@end
