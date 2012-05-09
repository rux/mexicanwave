//
//  MEXDataModel.m
//  MexicanWave
//
//  Created by Tom York on 29/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "MEXWaveModel.h"
#import "MEXCompassModel.h"
#import "ios-ntp/ios-ntp.h"

#define PERIOD_IN_SECONDS_FOR_SMALL_GROUP 7.5
#define PERIOD_IN_SECONDS_FOR_STAGE 15.0
#define PERIOD_IN_SECONDS_FOR_STADIUM 30.0

NSString* const MEXWaveModelDidWaveNotification = @"MEXWaveModelDidWaveNotification";
NSString* const MEXWaveSpeedSettingsKey = @"MEXWaveSpeedSettingsKey";

@interface MEXWaveModel ()
@property (nonatomic,retain) MEXCompassModel* compassModel;
@property (nonatomic,getter=isRunning) BOOL running;

- (void)waveDidPassOurBearing;
- (void)cancelWave;
- (void)scheduleWave;
@end

@implementation MEXWaveModel

@synthesize venueSize;
@synthesize compassModel;
@synthesize running;

+ (NSTimeInterval)wavePeriodInSecondsForCrowdType:(MEXVenueSize)venue {
    switch (venue) {
        case kMEXVenueSizeSmall:
            return PERIOD_IN_SECONDS_FOR_SMALL_GROUP;
            
        case kMEXVenueSizeMedium:
            return PERIOD_IN_SECONDS_FOR_STAGE;
            
        case kMEXVenueSizeLarge:
            return PERIOD_IN_SECONDS_FOR_STADIUM;
            
        default:
            NSAssert(NO, @"Unhandled crowd size enum value %d", venue);
            break;
    }
    return PERIOD_IN_SECONDS_FOR_STADIUM;
}


+ (NSSet*)keyPathsForValuesAffectingNumberOfPeaks {
    return [NSSet setWithObject:@"crowdType"];
}

+ (NSSet*)keyPathsForValuesAffectingWavePeriodInSeconds {
    return [NSSet setWithObject:@"crowdType"];
}

+ (NSSet*)keyPathsForValuesAffectingWavePhase {
    return [NSSet setWithObjects:@"compassModel.headingInDegreesEastOfNorth",@"crowdType",nil];
}

- (NSUInteger)numberOfPeaks {
    //return (self.crowdType == kMEXCrowdTypeStageBased) ? 2 : 1;
    return 1; // For now, we've agreed to just always use one peak to keep the UI simple.
}

- (NSTimeInterval)wavePeriodInSeconds {
    return [[self class] wavePeriodInSecondsForCrowdType:self.venueSize];
}

- (float)wavePhase {
    if(self.wavePeriodInSeconds <= 0.0f) {
        return 0.0f;
    }
    NSDate* correctedDate = [NSDate networkDate];
    return ((float)fmod([correctedDate timeIntervalSince1970] - (self.compassModel.headingInDegreesEastOfNorth / 360.0)*self.wavePeriodInSeconds, self.wavePeriodInSeconds))/self.wavePeriodInSeconds;
}

- (void)setVenueSize:(MEXVenueSize)newValue{
    if(venueSize != newValue) {
        [self willChangeValueForKey:@"crowdType"];
        venueSize = newValue;
        [[NSUserDefaults standardUserDefaults] setInteger:newValue forKey:MEXWaveSpeedSettingsKey];
        [self didChangeValueForKey:@"crowdType"];
        [self scheduleWave];
    }
}

#pragma mark - Waving

- (void)waveDidPassOurBearing {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:MEXWaveModelDidWaveNotification object:[NSNumber numberWithBool:YES]]];
    [self scheduleWave];

}

- (void)cancelWave {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waveDidPassOurBearing) object:nil];
}

- (void)scheduleWave {
    // In case we're called multiple times.
    [self cancelWave];

    if(self.wavePeriodInSeconds <= 0.0) {
        return;
    }
    
    const float timeToNextWave = self.wavePeriodInSeconds * (0.998 - self.wavePhase);
    [self performSelector:@selector(waveDidPassOurBearing) withObject:nil afterDelay:timeToNextWave];
}

- (void)pause {
    if(!self.isRunning) return;
    [self.compassModel stopCompass];
    [self cancelWave]; 
    self.running = NO;
}

- (void)resume {
    if(self.isRunning) return;

    // Read out our saved settings
    self.venueSize = (MEXVenueSize)[[[NSUserDefaults standardUserDefaults] valueForKey:MEXWaveSpeedSettingsKey] integerValue];    

    [self.compassModel startCompass];
    [self scheduleWave];    
    self.running = YES;
}
     
#pragma mark - Lifecycle

- (id)init {
    if(!(self = [super init])) {
        return nil;
    }
    compassModel = [[MEXCompassModel alloc] init];

    // Read out our saved settings
    self.venueSize = (MEXVenueSize)[[[NSUserDefaults standardUserDefaults] valueForKey:MEXWaveSpeedSettingsKey] integerValue];    
   
    // TODO: observe the network clock
    NSNotificationCenter* noteCenter = [NSNotificationCenter defaultCenter];
    [noteCenter addObserver:self selector:@selector(scheduleWave) name:UIApplicationSignificantTimeChangeNotification object:nil];        
    [noteCenter addObserver:self selector:@selector(scheduleWave) name:UIApplicationDidFinishLaunchingNotification object:nil];        

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelWave];
    [compassModel release];
    [super dealloc];
}

@end
