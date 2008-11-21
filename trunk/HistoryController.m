//
//  HistoryController.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 16.09.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "HistoryController.h"

#import "Song.h"
#import "TableColumnDateFormatter.h"

@implementation HistoryController

- (void)awakeFromNib {
//	[tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:YES];
	[tableView setVerticalMotionCanBeginDrag:NO];
	TableColumnDateFormatter* formatter = [[[TableColumnDateFormatter alloc] init] autorelease];
	NSTableColumn* tc = [tableView tableColumnWithIdentifier:@"datePlayed"];
	[formatter setTableColumn:tc];
//	[[tc headerCell] performClick:nil];
}

- (IBAction)clear:(id)sender {
	[history removeObjects:[history arrangedObjects]];
}

- (IBAction)exportPlaylist:(id)sender {
	NSSavePanel* savePanel = [NSSavePanel savePanel];
	
	NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	
	[savePanel setRequiredFileType:@"m3u"];
	[savePanel beginSheetForDirectory:nil 
								 file:[NSString stringWithFormat:@"Playlist %@.m3u", [formatter stringFromDate:[NSDate date]]] 
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) 
						  contextInfo:nil];
}

- (void)savePanelDidEnd:(NSSavePanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo {
	if (returnCode != NSOKButton) {
		return;
	}
	
	NSMutableString* pl = [@"#EXTM3U\n" mutableCopy];
	
	for (Song* song in [history arrangedObjects]) {
//		NSLog(@"#EXTINF:%d,%@\n%@", [[song duration] intValue], [song description], [song filename]);
		[pl appendFormat:@"#EXTINF:%d,%@\n%@\n", [[song duration] intValue], [song description], [song filename]];
	}
	
	
	NSError* error;
	if (![pl writeToFile:[sheet filename] atomically:YES encoding:NSISOLatin1StringEncoding error:&error]) {
		[[NSAlert alertWithError:error] runModal];
	}
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
		
	// create new array of selected rows for remote drop
    // could do deferred provision, but keep it direct for clarity
//	NSMutableArray *rowCopies = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
	NSMutableArray* filenames = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
	
    unsigned int currentIndex = [rowIndexes firstIndex];
    while (currentIndex != NSNotFound)
    {
		Song* s = [[history arrangedObjects] objectAtIndex:currentIndex];
//		[rowCopies addObject:s];
		[filenames addObject:[s filename]];
        currentIndex = [rowIndexes indexGreaterThanIndex: currentIndex];
    }
	
	//	[pboard setPropertyList:rowCopies forType:SongsType];
	[pboard setPropertyList:filenames forType:NSFilenamesPboardType];
//	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowCopies] forType:SongsType];
	
    return YES;
}

@end
