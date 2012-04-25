//
//  MEXCalibrationModel.m
//  MexicanWave
//
//  Created by Tom York on 01/03/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "MEXCompassModel.h"

#define kFilterStrength 0.25f

typedef struct {
    float north, east;
} MEXCompassVector;

@interface MEXCompassModel ()
@property (nonatomic,retain) CLLocationManager* locationManager;
@property (nonatomic,retain,readwrite) NSError* latestError;             
@property (nonatomic) MEXCompassVector compassVector;
@end

@implementation MEXCompassModel

@synthesize locationManager;
@synthesize compassVector;
@synthesize latestError;

+ (NSSet*)keyPathsForValuesAffectingHeadingInDegreesEastOfNorth {
    return [NSSet setWithObject:@"compassVector"];
}

- (float)headingInDegreesEastOfNorth {
    return 180.0f*atan2f(compassVector.east, compassVector.north)/(float)M_PI;
}

- (void)startCompass {
    [self.locationManager startUpdatingHeading];    
}

- (void)stopCompass {
    [self.locationManager stopUpdatingHeading];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {    
    // Create new heading vector by averaging with old one.
    const float latestHeadingAngle = M_PI*[newHeading magneticHeading]/180.0f;
    MEXCompassVector latestCompassVector = { sinf(latestHeadingAngle), cosf(latestHeadingAngle) };
    latestCompassVector.north = latestCompassVector.north * kFilterStrength + self.compassVector.north * (1.0f - kFilterStrength);
    latestCompassVector.east = latestCompassVector.east * kFilterStrength + self.compassVector.east * (1.0f - kFilterStrength);
    const float normalization = sqrtf(latestCompassVector.north*latestCompassVector.north + latestCompassVector.east*latestCompassVector.east);
    if(normalization > 0.0f) {
        // Normalize to avoid drift over time in the averaging.
        latestCompassVector.east /= normalization;
        latestCompassVector.north /= normalization;
    }
    // Update heading
    self.compassVector = latestCompassVector;
    // Clear existing error
    self.latestError = nil;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    self.latestError = error;
}

#pragma mark - Lifecycle
 
- (id)init {
    if(!(self = [super init])) {
        return nil;
    }
    
    if(!([CLLocationManager headingAvailable])) {
        [self release], self = nil;
        return nil;
    }
        
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    
    return self;
}

- (void)dealloc {
    [latestError release];
    [locationManager stopUpdatingHeading];
    [locationManager release];
    [super dealloc];
}

@end
