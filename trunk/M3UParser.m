//
//  M3UParser.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 13.10.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "M3UParser.h"


@implementation M3UParser

+ (NSArray*)filenamesInM3UFile:(NSString*)filename {
	NSMutableArray* filenames = [NSMutableArray array];
	NSString* dirname = [filename stringByDeletingLastPathComponent];
	NSError* error;
	NSStringEncoding encoding;
	NSArray* lines = [[NSString stringWithContentsOfFile:filename 
											usedEncoding:&encoding 
												   error:&error] componentsSeparatedByString:@"\n"];
	if (!lines) {
		return nil;
	}
	for (NSString* line in lines) {
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		if (([line length] > 0) && ([line characterAtIndex:0] != '#')) {
			if (![line isAbsolutePath]) {
				line = [dirname stringByAppendingPathComponent:line];
			}
			[filenames addObject:line];
		}
	}
	return filenames;
}


@end
