//
//  SpringLoadedButton.h
//  SimpleDJ
//
//  Created by Bernhard Bauer on 08.09.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSToolbarButton : NSButton
{
    NSToolbarItem *_item;
    SEL _primaryAction;
    SEL _alternateAction;
    NSString *_primaryToolTip;
    NSString *_alternateToolTip;
    NSString *_primaryTitle;
    NSString *_alternateTitle;
    NSImage *_cachedDrawingImage;
    struct {
        unsigned int drawing:1;
        unsigned int reserved:31;
    } _tbbFlags;
}

+ (void)initialize;
- (id)autorelease;
- (void)release;
- (id)initWithItem:(NSToolbarItem*)fp8;
- (void)dealloc;
- (NSToolbarItem*)_item;
- (void)setState:(int)fp8;
- (void)setImagePosition:(unsigned int)fp8;
- (BOOL)sendAction:(SEL)fp8 to:(id)fp12;
- (BOOL)sendAction;
- (BOOL)refusesFirstResponder;
- (void)invalidateCachedDrawingImage;
- (id)cachedDrawingImage;
- (void)setFrameSize:(struct _NSSize)fp8;
- (void)setImage:(NSImage*)fp8;
- (void)updateCellInside:(id)fp8;
- (void)drawRect:(struct _NSRect)fp8;

@end

@interface SpringLoadedToolbarButton : NSToolbarButton {
	NSTimer* activationTimer;
}

@end
