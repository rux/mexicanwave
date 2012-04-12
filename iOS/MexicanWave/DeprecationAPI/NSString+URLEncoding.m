//
//  NSString+URLEncoding.m
//  Yellevision
//
//  Created by Tom York on 31/01/2011.
//  Copyright 2011 Yell Group Plc. All rights reserved.
//

#import "NSString+URLEncoding.h"

static NSString* const kReservedURLCharacters =  @";/?:@&=!*#+$,%{}|^[]`'\"\\() ";

@implementation NSString (URLEncoding)

- (NSString*)stringByURLEncodingAsQueryParameter {
	NSString* newString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)self,NULL,(CFStringRef)kReservedURLCharacters,kCFStringEncodingUTF8);
    return [newString autorelease];	
}



@end
