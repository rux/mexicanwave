//
//  OmnitureLogging.h
//  MexicanWave
//
//  Created by Daniel Anderton on 12/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OmnitureLogging : NSObject

+(OmnitureLogging*)sharedInstance;      //<< Singleton for easy access.
-(void)postEventAppFinishedLaunching;   //<< Event is posted when the app screen is visable
-(void)postEventSettingsViewVisible;    //<< Event is posted when the user can 'fully' see the settings view
-(void)postEventLinkPressed;            //<< Event is posted when the user taps the download link for the Yell store
-(void)postEventLinkIsVisible;          //<< Event is posted when the user can see the download link for the Yell store (not shown if not in the UK)
@end
