//
//  YellAdvertView.h
//  MexicanWave
//
//  Created by Daniel Anderton on 18/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YellAdvertView : UIControl
- (NSString*)countryCodeForCurrentLocale;
- (NSString*)appstoreURLForCountryCode:(NSString*)countryCode;
- (void)commonInitialisation;
@end
