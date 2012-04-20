//
//  MEXCalibrationModel.h
//  MexicanWave
//
//  Created by Tom York on 01/03/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>


typedef void(^MEXCalibrationCompletionBlock)(float calibratedheadingInDegrees, NSError* error);


@interface MEXCompassModel : NSObject <CLLocationManagerDelegate>

@property (nonatomic,readonly) float headingInDegreesEastOfNorth;       // KVO this to get dynamic updates
@property (nonatomic,retain,readonly) NSError* latestError;             // KVO this to find out about errors.

- (void)startCompass;
- (void)stopCompass;
@end
