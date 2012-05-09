//
//  MEXDataModel.h
//  MexicanWave
//
//  Created by Tom York on 29/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kMEXVenueSizeSmall,
    kMEXVenueSizeMedium,
    kMEXVenueSizeLarge
} MEXVenueSize;

NSString* const MEXWaveModelDidWaveNotification;
NSString* const MEXWaveSpeedSettingsKey;

@interface MEXWaveModel : NSObject

+ (NSTimeInterval)wavePeriodInSecondsForCrowdType:(MEXVenueSize)venue;

@property (nonatomic) MEXVenueSize venueSize;
@property (nonatomic,readonly) NSTimeInterval wavePeriodInSeconds;
@property (nonatomic,readonly) NSUInteger numberOfPeaks;
@property (nonatomic,readonly) float wavePhase;

- (void)pause;
- (void)resume;

@end
