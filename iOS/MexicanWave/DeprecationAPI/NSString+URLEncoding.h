//
//  NSString+URLEncoding.h
//  Yellevision
//
//  Created by Tom York on 31/01/2011.
//  Copyright 2011 Yell Group Plc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 
 */
@interface NSString (URLEncoding)

- (NSString*)stringByURLEncodingAsQueryParameter;
@end
