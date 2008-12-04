//
//  Deck.h
//  SimpleDJ
//
//  Created by Bernhard Bauer on 05.07.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//#import "RoundedBox.h"

@class DeckController;

@interface Deck : NSBox {
	IBOutlet DeckController* controller;
	
	IBOutlet NSSlider* volumeSlider;
	
	BOOL isHighlighted;
}

- (BOOL)selected;
- (void)setSelected:(BOOL)selected;

@end
