//
//  Deck.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 05.07.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "Deck.h"

#import "DeckController.h"
#import "PlaylistController.h"
#import "Song.h"
#import "NSPasteboard+SimpleDJ.h"

@implementation Deck

- (BOOL)selected {
	return isHighlighted;
}
- (void)setSelected:(BOOL)isSelected {
	isHighlighted = isSelected;
	[self setNeedsDisplay:YES];
}

- (void)awakeFromNib {
//	[super awakeFromNib];
	
//	[self registerForDraggedTypes:[QTMovie movieUnfilteredPasteboardTypes]];
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, MovedRowsType, AIiTunesTrackPboardType, nil]];

//	[NSBundle loadNibNamed:@"Deck" owner:self];
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    NSPasteboard* pboard = [sender draggingPasteboard];
	NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
	if (!filenames) {
		filenames = [pboard filenamesFromITunesDragPasteboard];
	}
	id draggingSource = [sender draggingSource];
	
	//	NSLog(@"filenames: %@", filenames);
	//	NSLog(@"draggingSource: %@", draggingSource);
	
	if ((draggingSource != self) && ([filenames count] == 1) && [QTMovie canInitWithFile:[filenames objectAtIndex:0]]) {
//		isHighlighted = YES;
//		[self setNeedsDisplay:YES];
		[self setSelected:YES];
		
//		NSLog(@"current event: %@", [NSApp currentEvent]);
		if (([pboard availableTypeFromArray:[NSArray arrayWithObject:SongsType]] != nil) && !([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)) {
			return NSDragOperationMove;
		} else {
			return NSDragOperationCopy;
		}
	} else {
//		isHighlighted = NO;
//		[self setNeedsDisplay:YES];
		[self setSelected:NO];
		return NSDragOperationNone;
	}
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
//	isHighlighted = NO;
//	[self setNeedsDisplay:YES];
	[self setSelected:NO];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
//	isHighlighted = NO;
//	[self setNeedsDisplay:YES];
	[self setSelected:NO];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard* pboard = [sender draggingPasteboard];

//	NSLog(@"current event: %@", [NSApp currentEvent]);
	
	NSData* data;
	if (!([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) && (data = [pboard dataForType:MovedRowsType])) {
		NSIndexSet* movedRows = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		if ([movedRows count] == 1) {
			[controller deck:self receivedRow:[movedRows firstIndex]];
			return YES;
		}
	}
	if (data = [pboard dataForType:SongsType]) {
		NSArray* songs = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		if ([songs count] == 1) {
			[controller deck:self receivedSong:[songs objectAtIndex:0]];
			return YES;
		}
	}
	NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
	if (!filenames) {
		filenames = [pboard filenamesFromITunesDragPasteboard];
	}
	if ([filenames count] == 1) {
		[controller deck:self receivedFile:[filenames objectAtIndex:0]];
		return YES;
	}
	return NO;
}

- (void)drawRect:(NSRect)aRect {
	[super drawRect:aRect];
	if ([self selected]) {
		NSRect borderRect = [self borderRect];
		borderRect.size.height -= 4;
		[NSGraphicsContext saveGraphicsState];
		NSSetFocusRingStyle(NSFocusRingOnly);
		[[NSBezierPath bezierPathWithRect: NSInsetRect(borderRect,4,4)] fill];
		[NSGraphicsContext restoreGraphicsState];
	}
}

- (void)mouseDragged:(NSEvent*)theEvent {
	Song* song = [controller song];
	if (song != nil) {
		NSPasteboard* pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
		
		[pboard declareTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, SongsType, nil] owner:self];
		
		[pboard setPropertyList:[NSArray arrayWithObject:[song filename]] forType:NSFilenamesPboardType];
		[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithObject:song]] forType:SongsType];
		
		NSImage* dragImage = [controller dragImage];
		NSSize offset = [dragImage size];
		
		NSPoint point = [theEvent locationInWindow];
		point.x -= offset.width/2;
		point.y -= offset.height/2;
		
		[[self window] dragImage:dragImage
							  at:point
						  offset:NSMakeSize(0, 0) 
						   event:theEvent 
					  pasteboard:pboard 
						  source:self 
					   slideBack:YES];
	} else {
		[super mouseDown:theEvent];
	}
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
	if (operation == NSDragOperationMove) {
		[controller clearMovie:nil];
	}
}

@end
