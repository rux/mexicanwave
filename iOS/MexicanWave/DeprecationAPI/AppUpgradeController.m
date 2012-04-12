//
//  AppUpgradeController.m
//  YellForiPad
//
//  Created by Tom York on 26/01/2011.
//  Copyright 2011 Yell Group Plc. All rights reserved.
//

#import "AppUpgradeController.h"
#import "AppUpgradeModel.h"

#define kAutoDismissButtonIndex -2

#define kButtonTitleUpgradeNow NSLocalizedStringFromTable(@"Upgrade now", @"Deprecation", @"Button title; tap takes user to app store now")
#define kButtonTitleContinue NSLocalizedStringFromTable(@"Continue", @"Deprecation", @"Button title; tap closes alert")
#define kMessageTitleDeprecated NSLocalizedStringFromTable(@"This version is outdated", @"Deprecation", @"Alert message; app is deprecated but can be used")
#define kMessageTitleEndOfLife NSLocalizedStringFromTable(@"This version has been retired", @"Deprecation", @"Alert message; app cannot be used")

@interface AppUpgradeController ()
@property (nonatomic,retain) UIAlertView* upgradeAlert;
@end
 


@implementation AppUpgradeController

@synthesize upgradeAlert;


#pragma mark -
#pragma mark Notifications

- (void)displayAlert {
	[self.upgradeAlert dismissWithClickedButtonIndex:kAutoDismissButtonIndex animated:YES];
	self.upgradeAlert = nil;
	
	AppUpgradeModel* upgradeModel = [AppUpgradeModel sharedInstance];
	if((upgradeModel.appStatus <= MobileAppStatusOK) || (upgradeModel.appStatus > MobileAppStatusEndOfLife) || !upgradeModel.updateMessage) {
		// Nothing to do because the response out of range.
		return;
	}

	const BOOL hasUpgradeURL = ([upgradeModel updateURL] != nil);
	NSString* title = (upgradeModel.appStatus == MobileAppStatusEndOfLife) ? kMessageTitleEndOfLife : kMessageTitleDeprecated;
	NSString* cancelTitle = (upgradeModel.appStatus == MobileAppStatusEndOfLife && hasUpgradeURL) ? kButtonTitleUpgradeNow : kButtonTitleContinue;
	UIAlertView* newAlert = [[UIAlertView alloc] initWithTitle:title message:upgradeModel.updateMessage delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:nil];
	if(upgradeModel.appStatus == MobileAppStatusDeprecated && hasUpgradeURL) {
		[newAlert addButtonWithTitle:kButtonTitleUpgradeNow];
	}
	self.upgradeAlert = newAlert;
	[newAlert release];
	
	// Avoid clashing with view presentation animation 
	[self.upgradeAlert performSelector:@selector(show) withObject:nil afterDelay:0.0f];
}

- (void)applicationForegroundNotification:(NSNotification*)note {
	if([[AppUpgradeModel sharedInstance] appStatus] == MobileAppStatusEndOfLife && !self.upgradeAlert) {
		[self displayAlert];
	}
}

- (void)upgradeStatusNotification:(NSNotification*)note {
	[self displayAlert];
}



#pragma mark -
#pragma mark Lifecycle and configuration

- (id)init {
	if((self = [super init])) {
		// App control/update 
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(upgradeStatusNotification:) name:MobileAppStatusUpdateNotification object:nil];	

		[[AppUpgradeModel sharedInstance] issueUpdateRequestIfNecessary];

	}
	return self;
}

- (void)dealloc {
	[upgradeAlert release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark -
#pragma mark Implement UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
	self.upgradeAlert = nil;
	
	if(buttonIndex == kAutoDismissButtonIndex) {
		// We're getting rid of the alert to show another (updated) message, do nothing.
		return;
	}
	
	const NSInteger upgradeButtonIndex = [alertView numberOfButtons] - 1;	// Upgrade is always on the last button.	
	NSURL* upgradeURL = [[AppUpgradeModel sharedInstance] updateURL];		
	if(buttonIndex == upgradeButtonIndex && upgradeURL) {
		if([[UIApplication sharedApplication] canOpenURL:upgradeURL]) {
			[[UIApplication sharedApplication] openURL:upgradeURL];
		}
	}
}

@end
