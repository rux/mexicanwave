//
//  MobileAppStatus
//  Yellevision
//
//  Created by Tom York on 21/01/2011.
//  Copyright 2011 Yell Group Plc. All rights reserved.
//

#import "AppUpgradeModel.h"
#import "NSString+SBJSON.h"
#import "NSString+URLEncoding.h"
#import "UIDevice+DetailedModelName.h"

// Notification names
NSString* const MobileAppStatusUpdateNotification = @"MobileAppStatusChanged";

// JSON object field names in the API response
#define kVersionUpdateKey @"version_update"
#define kUpdateStatusKey @"update_status"
#define kUpdateMessageKey @"message"
#define kUpdateURLKey @"url"

#define kDefaultExpectedResponseLength 512

// Status codes in the API response
#define kUpdateStatusOK @"ok"
#define kUpdateStatusDeprecated @"deprecated"
#define kUpdateStatusEndOfLife @"endoflife"

// Timing defaults
#define kDefaultMinimumTimeBetweenChecksInSeconds (3600.0*24.0)	// Twenty-four hour interval
#define kConnectionTimeoutInterval 120.0

// Stores last upgrade query results
static NSString* const kUpgradeModelDictionaryFilename = @"LastUpgrade";

@interface AppUpgradeModel ()
@property (nonatomic,readwrite,copy) NSString* updatedByAppVersion;		
@property (nonatomic,readwrite,copy) NSDate* updatedOn;
@property (nonatomic,readwrite,copy) NSURL* updateURL;
@property (nonatomic,readwrite,copy) NSString* updateMessage;
@property (nonatomic,readwrite,assign) MobileAppStatus appStatus;

@property (nonatomic,readwrite,retain) NSMutableData* responseData;
@property (nonatomic,readwrite,assign) BOOL responseIsHTTPOK;
@end

@implementation AppUpgradeModel

#pragma mark -
#pragma mark Accessors

@synthesize platformName, applicationName, applicationVersion, applicationChannel;
@synthesize updatedOn, updatedByAppVersion;
@synthesize updateURL, updateMessage, appStatus;
@synthesize responseData, responseIsHTTPOK;
@synthesize minimumTimeBetweenUpdateRequests, updateServiceURL;

#pragma mark -
#pragma mark State persistence

- (NSString*)appControlStatePath {
	NSString* cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	if(!cachesDir) {
		return nil;
	}
	
	return [cachesDir stringByAppendingString:kUpgradeModelDictionaryFilename];
}

- (NSString*)internalVersionID {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
}

- (BOOL)loadState {
	NSData* lastArchivedState = [NSData dataWithContentsOfFile:[self appControlStatePath]];
	if(!lastArchivedState) {
		return NO;
	}
	NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:lastArchivedState];
	if(!unarchiver) {
		return NO;
	}
	
	self.updatedOn = [unarchiver decodeObjectForKey:@"LastUpdateTime"];
	self.appStatus = (MobileAppStatus)[unarchiver decodeIntForKey:@"LastUpdateOutcome"];
	self.updatedByAppVersion = [unarchiver decodeObjectForKey:@"ForVersion"];
	[unarchiver finishDecoding];
	[unarchiver release];

	return YES;
}

- (BOOL)saveState {	
	// Save to disk
	NSMutableData* archivableState = [[NSMutableData alloc] initWithCapacity:256];
	if(!archivableState) {
		return NO;
	}
	
	NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archivableState];
	if(!archiver) {
		[archivableState release];
		return NO;
	}
	
	[archiver encodeObject:self.updatedOn forKey:@"LastUpdateTime"];
	[archiver encodeInt:self.appStatus forKey:@"LastUpdateOutcome"];
	[archiver encodeObject:self.updatedByAppVersion forKey:@"ForVersion"];
	[archiver finishEncoding];
	[archiver release];

	const BOOL wroteArchive = [archivableState writeToFile:[self appControlStatePath] atomically:YES];
	[archivableState release];	
	return wroteArchive;
}

- (void)resetState {
	[[NSFileManager defaultManager] removeItemAtPath:[self appControlStatePath] error:nil];	

	self.appStatus = MobileAppStatusUnknown;
	self.updatedOn = [NSDate distantPast];
	self.updatedByAppVersion = [self internalVersionID];
	self.updateMessage = nil;
	self.updateURL = nil;
}

#pragma mark -
#pragma mark Convenience

- (void)resetConnectionState {
	[serviceConnection cancel];
	[serviceConnection release], serviceConnection = nil;
	self.responseData = nil;
	self.responseIsHTTPOK = NO;
}

#pragma mark -
#pragma mark Triggers for automatic updating

- (void)applicationDidBecomeActive:(NSNotification*)note {
	[self issueUpdateRequestIfNecessary];
}

#pragma mark -
#pragma mark Issue/cancel updates

- (void)issueUpdateRequestIfNecessary {
	if(serviceConnection) {
		// Already in progress.
		return;
	}
	
	BOOL needsUpdate = NO;
	switch(self.appStatus) {
		case MobileAppStatusDeprecated:	// Just check once every 24hours if we were deprecated last check
		case MobileAppStatusOK:			// Just check once every 24hours if we were OKed last check
		{
			needsUpdate = ([[NSDate date] timeIntervalSinceDate:self.updatedOn] > self.minimumTimeBetweenUpdateRequests);		
			break;
		}
			
		case MobileAppStatusUnknown:	// Always check if we've never checked status before
		case MobileAppStatusEndOfLife:	// Always check if we were endoflifed last check
		{
			needsUpdate = YES;
			break;
		}			
	}
	
	if(needsUpdate || ![self.updatedByAppVersion isEqualToString:[self internalVersionID]]) {
		[self forceUpdateRequest];
	}
}

- (void)forceUpdateRequest {
	// Cancel any outstanding request.
	[self resetConnectionState];

	// enforce minimum configuration
	NSAssert(self.updateServiceURL && self.platformName && self.applicationName && self.applicationVersion, @"Mobile Application Control not configured");
	if(!self.updateServiceURL || !self.platformName || !self.applicationName || !self.applicationVersion) {
		return;
	}	

    UIDevice* device = [UIDevice currentDevice];
    NSString* systemName = [[device detailedModelName] stringByURLEncodingAsQueryParameter];
    NSString* osVersion = [[device systemVersion] stringByURLEncodingAsQueryParameter];
    NSString* applicationId = [[NSString stringWithFormat:@"%@|%@|%@|%@", self.platformName, self.applicationName, self.applicationVersion, self.applicationChannel ? self.applicationChannel : @"-"] stringByURLEncodingAsQueryParameter];
    NSString* encodedAppName = [self.applicationName stringByURLEncodingAsQueryParameter];
    NSString* encodedVersion = [self.applicationVersion stringByURLEncodingAsQueryParameter];
    
	// Formulate query from configuration.	
	NSString* urlAsString = [[NSString alloc] initWithFormat:@"%@?applicationid=%@&platform=%@&application=%@&version=%@&device=%@&system=%@", self.updateServiceURL.absoluteString, applicationId, self.platformName, encodedAppName, encodedVersion, systemName, osVersion];
    NSString* encodedChannel = self.applicationChannel.length ? [self.applicationChannel stringByURLEncodingAsQueryParameter] : @"-";
    [urlAsString stringByAppendingFormat:@"&channel=%@", encodedChannel];
	
	// Issue request.
	NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlAsString] cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:kConnectionTimeoutInterval];
	[urlAsString release];
	serviceConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[request release];
}


- (void)flushPersistedState {
	[self resetState];
}

#pragma mark -
#pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
	long long expectedContentLength = [response expectedContentLength];
	if(expectedContentLength == NSURLResponseUnknownLength || expectedContentLength > UINT_MAX) {
		expectedContentLength = kDefaultExpectedResponseLength;
	}
	
	self.responseData = [NSMutableData dataWithCapacity:(NSUInteger)expectedContentLength];
	if([response respondsToSelector:@selector(statusCode)]) {
		self.responseIsHTTPOK = ([(NSHTTPURLResponse*)response statusCode] == 200);		
	}
	else {
		self.responseIsHTTPOK = NO;
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// Record this update attempt. Failure to parse results in OK state.
	self.updatedOn = [NSDate date];		
	self.appStatus = MobileAppStatusOK;
	self.updateMessage = nil;
	self.updateURL = nil;
	self.updatedByAppVersion = [self internalVersionID];
	
	if(self.responseIsHTTPOK) {
		// Got some sort of response body.
		if([responseData length]) {
            NSString* responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
			NSObject* parsedResponse = [responseString JSONValue];
            [responseString release];
            
			if([parsedResponse isKindOfClass:[NSDictionary class]]) {
				NSObject* parsedVersionUpdateInfo = [(NSDictionary*)parsedResponse valueForKey:kVersionUpdateKey];
				if([parsedVersionUpdateInfo isKindOfClass:[NSDictionary class]]) {
					NSString* updateStatusField = [[[parsedVersionUpdateInfo valueForKey:kUpdateStatusKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
					NSUInteger statusFromMapping = [appStatusMapping indexOfObject:updateStatusField];
					if(statusFromMapping != NSNotFound) {
						self.appStatus = statusFromMapping;
						self.updateMessage = [parsedVersionUpdateInfo valueForKey:kUpdateMessageKey];
						NSString* responseUpdateURL = [parsedVersionUpdateInfo valueForKey:kUpdateURLKey];
						if(responseUpdateURL) {
							self.updateURL = [NSURL URLWithString:responseUpdateURL];
						}
					}
				}
			}
		}
	}
	[self resetConnectionState];

	[self saveState];

	// Announce an update.
	NSNotification* changeNotification = [NSNotification notificationWithName:MobileAppStatusUpdateNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotification:changeNotification];		
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	// Just give up and wait until triggered again by an environment event.
	[self resetConnectionState];

	// Assume OK
	self.updatedOn = [NSDate date];		
	self.appStatus = MobileAppStatusOK;
	self.updateMessage = nil;
	self.updateURL = nil;
	self.updatedByAppVersion = [self internalVersionID];
	
	[self saveState];

	// Announce an update.
	NSNotification* changeNotification = [NSNotification notificationWithName:MobileAppStatusUpdateNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotification:changeNotification];			
}

#pragma mark -
#pragma mark Lifecycle

- (id)init {
	if((self = [super init])) {		
		appStatusMapping = [[NSArray alloc] initWithObjects:kUpdateStatusOK, kUpdateStatusDeprecated, kUpdateStatusEndOfLife,nil];

		// App status initialisation		
		if(![self loadState]) {
			[self resetState];
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];		
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[appStatusMapping release];
	[serviceConnection release];
	[responseData release];
	
	[updateServiceURL release];
	[platformName release];
	[applicationName release];
	[applicationVersion release];
	[applicationChannel release];
	
	[updatedOn release];
	[updateMessage release];
	[updateURL release];
	[super dealloc];
}

#pragma mark -
#pragma mark Singleton

+ (id)sharedInstance {
	static dispatch_once_t token;
	static id instance = nil;	
	dispatch_once(&token, ^{ instance = [[self alloc] init]; });
	return instance;		
}

#pragma mark -
#pragma mark Description

- (NSString*)description {
	NSString* upgradeStatusString = @"Unknown";
	if(self.appStatus >= 0 && self.appStatus < (NSInteger)[appStatusMapping count]) {
		upgradeStatusString = [appStatusMapping objectAtIndex:self.appStatus];
	}
	return [NSString stringWithFormat:@"%@ (%p) { updatedOn: %@\nupdateStatus: %d (%@)\nupdateMessage: %@\nupdateURL: %@\n}\n", NSStringFromClass([AppUpgradeModel class]), self, self.updatedOn, self.appStatus, upgradeStatusString, self.updateMessage, self.updateURL ]; 	
}

@end
