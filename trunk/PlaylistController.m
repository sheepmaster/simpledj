
/* 
 Copyright (c) 2004-7, Apple Computer, Inc., all rights reserved.
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2004-7 Apple Inc. All Rights Reserved.
 */



#import "PlaylistController.h"
//#import "MyDocument.h"
#import "Song.h"
#import "Deck.h";
#import "SpringLoadedToolbarButton.h"
#import "PlaylistToolbarItem.h"
#import "NSPasteboard+SimpleDJ.h"

NSString* MovedRowsType = @"MOVED_ROWS_TYPE";



/*
 Utility method to retrieve the number of indexes in a given range
 */
@interface NSIndexSet (CountOfIndexesInRange)
-(unsigned int)countOfIndexesInRange:(NSRange)range;
@end



@implementation PlaylistController



- (void)awakeFromNib
{
    // register for drag and drop
    
//	[tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
	[tableView setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationMove) forLocal:YES];
	
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:SongsType, MovedRowsType, NSURLPboardType, AIiTunesTrackPboardType, nil]];
//    [tableView setAllowsMultipleSelection:YES];
	
	[super awakeFromNib];
}



- (BOOL)tableView:(NSTableView *)aTableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes
	 toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:[NSArray arrayWithObjects:SongsType, MovedRowsType, NSFilenamesPboardType, nil] owner:self];
	
	
	
    // add rows array for local move
	NSData *rowIndexesArchive = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard setData:rowIndexesArchive forType:MovedRowsType];
	
	// create new array of selected rows for remote drop
    // could do deferred provision, but keep it direct for clarity
	NSMutableArray *rowCopies = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
	NSMutableArray* filenames = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
	
    unsigned int currentIndex = [rowIndexes firstIndex];
    while (currentIndex != NSNotFound)
    {
		Song* s = [[self arrangedObjects] objectAtIndex:currentIndex];
		[rowCopies addObject:s];
		[filenames addObject:[s filename]];
        currentIndex = [rowIndexes indexGreaterThanIndex: currentIndex];
    }

	
//	[pboard setPropertyList:rowCopies forType:SongsType];
	[pboard setPropertyList:filenames forType:NSFilenamesPboardType];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowCopies] forType:SongsType];
	
    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
    
    NSDragOperation dragOp = NSDragOperationCopy;
    id source = [info draggingSource];
	
    // if drag source is self, it's a move unless the Option key is pressed
    if ((source == tableView) || [source isKindOfClass:[Deck class]]) {
		
		NSEvent *currentEvent = [NSApp currentEvent];
		int optionKeyPressed = [currentEvent modifierFlags] & NSAlternateKeyMask;
		if (optionKeyPressed == 0) {
			dragOp =  NSDragOperationMove;
		}
	}
	
    // we want to put the object at, not over,
    // the current row (contrast NSTableViewDropOn) 
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOp;
}



- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)op
{
    if (row < 0) {
		row = 0;
	}
	
	NSPasteboard* pboard = [info draggingPasteboard];
	
	// if drag source is self, it's a move unless the Option key is pressed
    if ([info draggingSource] == tableView) {
		
		NSEvent *currentEvent = [NSApp currentEvent];
		int optionKeyPressed = [currentEvent modifierFlags] & NSAlternateKeyMask;
		
		if (optionKeyPressed == 0) {
			
			NSData *rowsData = [pboard dataForType:MovedRowsType];
			NSIndexSet *indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:rowsData];
			
			NSIndexSet *destinationIndexes = [self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
			// set selected rows to those that were just moved
			[self setSelectionIndexes:destinationIndexes];
			
			return YES;
		}
    }
	
	NSMutableArray* newRows = nil;
	
	// Can we get rows from another document?  If so, add them, then return.
	
	NSData* data = [pboard dataForType:SongsType];
	NSArray* filenames;
	if (data) {
		newRows = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	} else if ((filenames = [pboard propertyListForType:NSFilenamesPboardType]) || (filenames = [pboard filenamesFromITunesDragPasteboard])) {
		newRows = [NSMutableArray arrayWithCapacity:[filenames count]];
		for (NSString* file in filenames) {
			Song* song = [[Song alloc] initWithFilename:file];
			if (song) {
				[newRows addObject:song];
				[song release];
			}
		}
	}
		
	if (newRows) {
		NSRange range = NSMakeRange(row, [newRows count]);
		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
		
		[self insertObjects:newRows atArrangedObjectIndexes:indexSet];
		// set selected rows to those that were just copied
		[self setSelectionIndexes:indexSet];
		return YES;
	}
	
	// Can we get an URL?  If so, add a new row, configure it, then return.
	NSURL *url = [NSURL URLFromPasteboard:pboard];
	
	if (url) {
		Song* newObject = [[Song alloc] initWithURL:url];
		[self insertObject:newObject atArrangedObjectIndex:row];
		[newObject release];
		
		// set selected rows to those that were just copied
		[self setSelectionIndex:row];
		return YES;		
	}
	
	
    return NO;
}



-(NSIndexSet *) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)fromIndexSet
												toIndex:(unsigned int)insertIndex
{	
	// If any of the removed objects come before the insertion index,
	// we need to decrement the index appropriately
	unsigned int adjustedInsertIndex =
	insertIndex - [fromIndexSet countOfIndexesInRange:NSMakeRange(0, insertIndex)]; 
	NSRange destinationRange = NSMakeRange(adjustedInsertIndex, [fromIndexSet count]);
	NSIndexSet *destinationIndexes = [NSIndexSet indexSetWithIndexesInRange:destinationRange];
	
	NSArray *objectsToMove = [[self arrangedObjects] objectsAtIndexes:fromIndexSet];
	[self removeObjectsAtArrangedObjectIndexes:fromIndexSet];	
	[self insertObjects:objectsToMove atArrangedObjectIndexes:destinationIndexes];
	
	return destinationIndexes;
}

/*
- (void)toolbarWillAddItem:(NSNotification *)notification {
	NSLog(@"toolbarWillAddItem: %@", notification);
	NSToolbarItem* item = [[notification userInfo] objectForKey:@"item"];
	if ([item isKindOfClass:[PlaylistToolbarItem class]]) {
		[[item view] registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, SongsType, nil]];
	}
}
*/

- (NSNumber*)totalDuration {
	float total = 0;
	NSArray* songs = [self arrangedObjects];
	if ([songs count] > 0) {
		for (Song* s in songs) {
			total += [[s duration] floatValue];
		}
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		
		if ([defaults boolForKey:@"AutoCrossfade"]) {
			total -= 1000*([defaults floatForKey:@"FadeInTime"] + [defaults floatForKey:@"FadeOutTime"]) * ([songs count] - 1);
		}
	}
	
	return [NSNumber numberWithFloat:total];
}

@end



/*
 Implementation of NSIndexSet utility category
 */
@implementation NSIndexSet (CountOfIndexesInRange)

-(unsigned int)countOfIndexesInRange:(NSRange)range {
	
	if (range.length == 0) {
		return 0;	
	}
	
	unsigned int start = range.location;
	unsigned int end = start + range.length;
	unsigned int count = 0;
	
	unsigned int currentIndex = [self indexGreaterThanOrEqualToIndex:start];
	
	while ((currentIndex != NSNotFound) && (currentIndex < end)) {
		count++;
		currentIndex = [self indexGreaterThanIndex:currentIndex];
	}
	
	return count;
}
@end


