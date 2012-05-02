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
NSString* const MetricsAppStoreLinkName = @"iOS/MexicanWave/AppStore";

@implementation UsageMetrics

#pragma mark - metrics service specific methods

- (AppMeasurement*)configuredMeasurementInstance {
    AppMeasurement* measurement = [AppMeasurement getInstance];
    NSAssert(measurement, @"Unable to obtain AppMeasurement instance");
    if(!measurement) {
        return nil;
    }

    [measurement clearVars];
    measurement.channel = MetricsChannel;
    measurement.useBestPractices = YES;
    measurement.currencyCode = @"GBP";
    measurement.linkTrackEvents = @"";
    measurement.linkTrackVars = @"";

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
    measurement.ssl = NO;
#else
	// Not debug builds.
	measurement.debugTracking = NO;
    measurement.ssl = YES;
#endif			
	/* WARNING: Changing any of the below variables will cause drastic changes
	 to how your visitor data is collected.  Changes should only be made
	 when instructed to do so by your account manager.*/
	measurement.trackingServer = @"yellgroup.122.2o7.net";		
	measurement.trackingServerSecure = @"syellgroup.122.2o7.net";		

    return measurement;
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
    if(![self configuredMeasurementInstance]) {
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
- (void)didShowMainPageWithDownloadLink:(BOOL)showsDownloadLink {
    AppMeasurement* measurement = [self configuredMeasurementInstance];
    measurement.pageName = MetricsMainPageName;
    measurement.prop6 = showsDownloadLink ? @"Link-Displayed" : @"Link-Not-Displayed";
    [measurement track];
}

//post event where the Yell download button link has been pressed
- (void)didFollowDownloadLinkForAppStore:(NSString*)appStore {
    AppMeasurement* measurement = [self configuredMeasurementInstance];
    measurement.pageName = MetricsMainPageName;
    NSString* appStoreLink = [NSString stringWithFormat:@"%@/%@", MetricsAppStoreLinkName, appStore];
    [measurement trackLink:nil linkType:@"e" linkName:appStoreLink];
}


@end
