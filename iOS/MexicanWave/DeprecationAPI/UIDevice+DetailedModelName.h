//
//  UIDevice+DetailedModelName.h
//  Loyalty
//
//  Created by Tom York on 12/08/2011.
//  Copyright 2011 Yell Group Plc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 This category adds a method to UIDevice to obtain the detailed machine name. 
 */
@interface UIDevice (DetailedModelName)

/**
 Obtains the detailed machine name.
 For example, where -[UIDevice model] returns "iPhone" for all iPhone devices, 
 this would return "iPhone3,1" on the iPhone 4, "iPhone2,1" on the 3GS, etc.
 NOTE: This should never be used to enable/disable particular application features. 
 Instead, test for the features you wish to use directly. This category is mainly 
 of use for reporting/diagnostics.
 
 @return The detailed machine name. If the detailed machine name cannot be accessed,
 it falls back to returning -[UIDevice model].
 */
- (NSString*)detailedModelName;
@end
