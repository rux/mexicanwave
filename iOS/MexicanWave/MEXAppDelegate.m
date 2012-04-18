//
//  MEXAppDelegate.m
//  MexicanWave
//
//  Created by Tom York on 29/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "MEXAppDelegate.h"
#import "MEXWavingViewController.h"
#import "SettingsModel.h"
#import "AppUpgradeModel.h"

@interface MEXAppDelegate ()
// -- App upgrade model (upgrade encouragement support) --
@property (nonatomic, retain)  AppUpgradeController* upgradeController;
@property (nonatomic, retain)  SettingsModel* settingsModel;
- (void)loadConfiguration;
@end

@implementation MEXAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize upgradeController,settingsModel;
- (void)dealloc
{
    [settingsModel release];
    [upgradeController release];
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self loadConfiguration];
    
    // Upgrade controller shows an alert if the app is deprecated or end-of-lifed.
	self.upgradeController = [[[AppUpgradeController alloc] init] autorelease];	
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self.viewController pause];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
   
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

/**
 Configure the upgrade model
 */
- (void)loadConfiguration {
    
    NSString* pathToConfigFile = [[NSBundle mainBundle] pathForResource:@"AppUpgradeConfiguration" ofType:@"plist"];
	NSDictionary* configDictionary = [NSDictionary dictionaryWithContentsOfFile:pathToConfigFile];
    
    settingsModel = [[SettingsModel alloc]initWithDictionary:configDictionary];
    
	// Configure deprecation service
	AppUpgradeModel* upgradeModel = [AppUpgradeModel sharedInstance];	
	upgradeModel.applicationName = settingsModel.appName;
	upgradeModel.platformName = settingsModel.platformName;
	upgradeModel.applicationVersion = settingsModel.appVersion;
	upgradeModel.updateServiceURL = settingsModel.upgradeServiceURL;
	if(settingsModel.upgradeCheckInterval) {
		upgradeModel.minimumTimeBetweenUpdateRequests = [settingsModel.upgradeCheckInterval doubleValue];
	}	
}
@end
