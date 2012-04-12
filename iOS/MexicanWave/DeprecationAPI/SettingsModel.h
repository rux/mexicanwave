//
//  SettingsModel.h
//  Loyalty
//
//  Created by Tom York on 29/11/2011.
//  Copyright (c) 2011 Yell Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsModel : NSObject

// Properties of general use
@property (nonatomic,copy,readonly) NSString* appVersion;

// App upgrade properties
@property (nonatomic,copy,readonly) NSString* platformName;
@property (nonatomic,copy,readonly) NSString* appName;
@property (nonatomic,copy,readonly) NSURL* upgradeServiceURL;
@property (nonatomic,copy,readonly) NSNumber* upgradeCheckInterval;



- (id)initWithContentsOfFile:(NSString*)plistFilename;
// Designated init
- (id)initWithDictionary:(NSDictionary*)configDictionary;

@end
