//
//  OmnitureLogging.m
//  MexicanWave
//
//  Created by Daniel Anderton on 12/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "OmnitureLogging.h"

@implementation OmnitureLogging
#pragma mark -
#pragma mark Lifecycle

- (id)init {
	if((self = [super init])) {		
		//configure onimature in here	
	}
	return self;
}

- (void)dealloc {
	
	[super dealloc];
}

+ (OmnitureLogging*)sharedInstance {
	static dispatch_once_t token;
	static id instance = nil;	
	dispatch_once(&token, ^{ instance = [[self alloc] init]; });
	return instance;		
}

//post event when the has just appeared
-(void)postEventAppFinishedLaunching{
    NSLog(@"**OmnitureLogging - AppFinishedLaunching");
    
}

//post event when setttings view is visible so we can track users that view - to pressed download link
-(void)postEventSettingsViewVisible{
    NSLog(@"**OmnitureLogging - EventSettingsViewVisible");    
}

//post event where the Yell download button link has been pressed
-(void)postEventLinkPressed{
    NSLog(@"**OmnitureLogging - EventLinkPressed");    
}

//post event that the user was in a country where the button was Visible
-(void)postEventLinkIsVisible{
    NSLog(@"**OmnitureLogging - EventLinkIsVisible");    
}


@end
