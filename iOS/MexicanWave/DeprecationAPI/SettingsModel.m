//
//  SettingsModel.m
//  Loyalty
//
//  Created by Tom York on 29/11/2011.
//  Copyright (c) 2011 Yell Group. All rights reserved.
//

#import "SettingsModel.h"



@implementation SettingsModel

@synthesize appVersion;
@synthesize platformName, appName, upgradeServiceURL, upgradeCheckInterval;



#pragma mark - Lifecycle

- (void)configureUpgradePropertiesWithDictionary:(NSDictionary*)dictionary {
    platformName = [[dictionary valueForKey:@"AppControlPlatformName"] copy];
    appName = [[dictionary valueForKey:@"AppControlAppName"] copy];
    upgradeServiceURL = [[NSURL alloc] initWithString:[dictionary valueForKey:@"AppControlServiceURL"]];
    upgradeCheckInterval = [[dictionary valueForKey:@"AppControlMinTimeBetweenUpdatesInSeconds"] copy];
}

- (id)initWithContentsOfFile:(NSString *)plistFilename {
    NSString* pathToConfigFile = [[NSBundle mainBundle] pathForResource:plistFilename ofType:@"plist"];
	NSDictionary* configDictionary = [NSDictionary dictionaryWithContentsOfFile:pathToConfigFile];
    return [self initWithDictionary:configDictionary];
}

- (id)initWithDictionary:(NSDictionary *)configDictionary {
    NSAssert(configDictionary, @"Require configuration settings");

    if(!(self = [super init])) {
        return nil;
    }

    appVersion = [[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"] copy];
   
    [self configureUpgradePropertiesWithDictionary:configDictionary];
  
    return self;
}

- (void)dealloc {
    [appVersion release];
    [platformName release];
    [appName release];
    [upgradeServiceURL release];
    [upgradeCheckInterval release];

    [super dealloc];
}

@end
