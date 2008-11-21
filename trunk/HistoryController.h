//
//  HistoryController.h
//  SimpleDJ
//
//  Created by Bernhard Bauer on 16.09.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HistoryController : NSWindowController {
	IBOutlet NSArrayController* history;
	
	IBOutlet NSTableView* tableView;
	
	IBOutlet NSPopUpButton* clearHistoryPopup;
}

- (IBAction)clear:(id)sender;
- (IBAction)exportPlaylist:(id)sender;

@end
