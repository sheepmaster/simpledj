//
//  TimeFormatter.m
//  SimpleDJ
//
//  Created by Bernhard Bauer on 18.07.08.
//  Copyright 2008 Black Sheep Software. All rights reserved.
//

#import "TimeFormatter.h"


@implementation TimeFormatter

- (NSString *)stringForObjectValue:(id)anObject{
    if (![anObject isKindOfClass:[NSNumber class]]) {
        return nil;
    }
	float time = [anObject floatValue];
	float abs_time = fabs(time);
	int hundreths = (int)(fmod(abs_time, 1)*100);
	int seconds = (int)trunc(abs_time);
	div_t hours = div(seconds,3600);
	div_t minutes = div(hours.rem,60);
	
	NSString* sign = signbit(time) ? @"-" : @"";
	
	if (hours.quot == 0) {
		return [NSString stringWithFormat:@"%@%d:%02d.%02d", sign, minutes.quot, minutes.rem, hundreths];
	}
	else {
		return [NSString stringWithFormat:@"%@%d:%02d:%02d.%02d", sign, hours.quot, minutes.quot, minutes.rem, hundreths];
	}	
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes {
	return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:anObject] attributes:attributes] autorelease];	
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
	*anObject = nil;
	*error = @"Not implemented";
	return NO;
}

@end
