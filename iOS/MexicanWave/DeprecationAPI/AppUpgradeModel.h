//
//  MobileAppStatus.h
//  Yellevision
//
//  Created by Tom York on 21/01/2011.
//  Copyright 2011 Yell Group Plc. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString* const MobileAppStatusUpdateNotification;		// Sent when an update attempt completes.

// States that an application can be in, with the addition of an unknown state for when the system has not yet received an update.
typedef enum {
	MobileAppStatusUnknown = -1,	// The model has not yet managed to obtain information from the Mobile App Control service.
	MobileAppStatusOK,				// The app does not require an upgrade
	MobileAppStatusDeprecated,		// The app has been deprecated, upgrade is desirable
	MobileAppStatusEndOfLife		// the app has expired, upgrade is urgent
} MobileAppStatus;					

/*
 This model uses the Mobile App Control service to obtain information on the validity of the installed version of this application.
 Once configured, it watches for the app being moved into the active state, and as long as the last update attempt was more than a 
 specified time ago, it contacts App Control to refresh the information.
 
 A notification is issued on success or failure. Most apps will only need the success notification; on receiving it, they should
 check the app status to determine whether the app is still valid or needs to be upgraded. The App Control service provides a message
 and an optional URL which are made available through this model when they are available.
 */
@interface AppUpgradeModel : NSObject {
	@private
	NSURLConnection* serviceConnection;
	NSArray* appStatusMapping;
}

// The model is a singleton.
+ (AppUpgradeModel*)sharedInstance;

// Configuration properties
@property (nonatomic,assign) NSTimeInterval minimumTimeBetweenUpdateRequests;
@property (nonatomic,copy) NSURL* updateServiceURL;
@property (nonatomic,copy) NSString* platformName;
@property (nonatomic,copy) NSString* applicationName;
@property (nonatomic,copy) NSString* applicationVersion;
@property (nonatomic,copy) NSString* applicationChannel;

// These properties let you determine the freshness of the retrieved data.
@property (nonatomic,copy,readonly) NSDate* updatedOn;					// Time that the last successful update was completed on.

// These properties show the latest state retrieved from the service. 
@property (nonatomic,assign,readonly) MobileAppStatus appStatus;	//   
@property (nonatomic,copy,readonly) NSString* updateMessage;		// Message received for user display from MAC service or nil.
@property (nonatomic,copy,readonly) NSURL* updateURL;

- (void)forceUpdateRequest;				// Forces an update attempt irrespective of the time the last attempt was made.
- (void)issueUpdateRequestIfNecessary;	// Makes an update attempt only if more than minimumTimeBetweenUpdates has elapsed since last attempt.
- (void)flushPersistedState;			// Used in testing.

@end
