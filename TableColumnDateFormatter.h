//
//  TableColumnDateFormatter.h
//
//  Created by John Chang on 2007-06-07.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import <Cocoa/Cocoa.h>


@interface TableColumnDateFormatter : NSFormatter {	
	NSDateFormatter * _dateFormatter, * _timeFormatter;
	NSArray * _dateFormats, * _relativeDateFormats;

	NSTableColumn * _tableColumn;
}

- (id) init;

- (void) setTableColumn:(NSTableColumn *)tableColumn;

@end
