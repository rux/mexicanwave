//
//  Metrics.m
//  MexicanWave
//
//  Created by Daniel Anderton on 12/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "UsageMetrics.h"
#import "AppMeasurement.h"

@implementation UsageMetrics
#pragma mark -
#pragma mark Lifecycle

- (id)init {
	if(!(self = [super init])) {		
        return nil;
	}
    
    AppMeasurement* measurement = [AppMeasurement getInstance];
    measurement.account = @"yelllabsdev";
    measurement.ssl = YES;
    
	return self;
}

- (void)dealloc {
	
	[super dealloc];
}

+ (UsageMetrics*)sharedInstance {
	static dispatch_once_t token;
	static id instance = nil;	
	dispatch_once(&token, ^{ instance = [[self alloc] init]; });
	return instance;		
}

//post event when the has just appeared
-(void)postEventAppFinishedLaunching{
    NSLog(@"**Metrics - AppFinishedLaunching");
    
}

//post event when setttings view is visible so we can track users that view - to pressed download link
-(void)postEventSettingsViewVisible{
    NSLog(@"**Metrics - EventSettingsViewVisible");    
}

//post event where the Yell download button link has been pressed
-(void)postEventLinkPressed{
    NSLog(@"**Metrics - EventLinkPressed");    
}

//post event that the user was in a country where the button was Visible
-(void)postEventLinkIsVisible{
    NSLog(@"**Metrics - EventLinkIsVisible");    
}


@end
