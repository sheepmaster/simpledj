//
//  NSPasteboard+SimpleDJ.h
//  SimpleDJ
//
//  Created by Bernhard Bauer on 27.10.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define AIiTunesTrackPboardType @"CorePasteboardFlavorType 0x6974756E" /* CorePasteboardFlavorType 'itun' */

@interface NSPasteboard(SimpleDJ)

- (NSArray *)filenamesFromITunesDragPasteboard;

@end
