//
//  Metrics.m
//  MexicanWave
//
//  Created by Daniel Anderton on 12/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "UsageMetrics.h"
#import "AppMeasurement.h"

NSString* const MetricsChannel = @"iOS/MexicanWave";
NSString* const MetricsMainPageName = @"iOS/MexicanWave";
NSString* const MetricsAdvertPageName = @"iOS/MexicanWave";
NSString* const MetricsAppStoreLinkName = @"iOS/MexicanWave/AppStore";

@implementation UsageMetrics

#pragma mark - metrics service specific methods

- (BOOL)configureMetrics {
    AppMeasurement* measurement = [AppMeasurement getInstance];
    
    NSAssert(measurement, @"Unable to obtain AppMeasurement instance");
    if(!measurement) {
        return NO;
    }
    
    measurement.channel = MetricsChannel;
    measurement.ssl = YES;
    measurement.useBestPractices = YES;
    measurement.trackOffline = YES;
    measurement.offlineLimit = 30;
    
    /* Specify the Report Suite ID(s) to track here */
#ifndef APPSTORERELEASE
	// All configurations except the app store release use the development suite
	measurement.account = @"yelllabsdev";
#else
	// The app store release uses the release suite
	measurement.account = @"yelllabs";			
#endif
	
	/* Turn on and configure debugging here */
#ifdef DEBUG 
	// DEBUG is defined for debug builds
	measurement.debugTracking = YES;
#else
	// Not debug builds.
	measurement.debugTracking = NO;
#endif			
	/* WARNING: Changing any of the below variables will cause drastic changes
	 to how your visitor data is collected.  Changes should only be made
	 when instructed to do so by your account manager.*/
    measurement.dc = @"122";
	measurement.trackingServer = @"yellgroup.122.2o7.net";		
	measurement.trackingServerSecure = @"syellgroup.122.2o7.net";		

    return YES;
}

#pragma mark - Lifecycle

+ (UsageMetrics*)sharedInstance {
	static dispatch_once_t token;
	static id instance = nil;	
	dispatch_once(&token, ^{ instance = [[self alloc] init]; });
	return instance;		
}

- (id)init {
	if(!(self = [super init])) {		
        return nil;
	}
    if(![self configureMetrics]) {
        [self release], self = nil;
        return nil;
    }
    
	return self;
}

- (void)dealloc {
	
	[super dealloc];
}

#pragma mark - Events

//post event when the has just appeared
- (void)didFinishLaunching {
    AppMeasurement* measurement = [AppMeasurement getInstance];
    [measurement clearVars];
    measurement.channel = MetricsChannel;
    measurement.pageName = MetricsMainPageName;
    [measurement track];
}

//post event where the Yell download button link has been pressed
- (void)didFollowDownloadLinkForAppStore:(NSString*)appStore {
    AppMeasurement* measurement = [AppMeasurement getInstance];
    [measurement clearVars];
    measurement.channel = MetricsChannel;
    measurement.pageName = MetricsMainPageName;
    NSString* appStoreLink = [NSString stringWithFormat:@"%@/%@", MetricsAppStoreLinkName, appStore];
    [measurement trackLink:nil linkType:@"e" linkName:appStoreLink];
}

//post event that the user was in a country where the button was Visible
- (void)didShowDownloadLink {
    AppMeasurement* measurement = [AppMeasurement getInstance];
    [measurement clearVars];
    measurement.channel = MetricsChannel;
    measurement.pageName = MetricsAdvertPageName;
    [measurement track];
}


@end
