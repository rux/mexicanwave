//
//  UserGuideView.h
//  MexicanWave
//
//  Created by Daniel Anderton on 24/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MEXWaveFxView.h"
typedef enum{
    kWaveFunTag = 200,
    kWaveGigTag = 201,
    kWaveStaduimTag = 202,
} MEXWaveSelection;
NSString* const kSpeedSegementDidChange;

@interface MEXWaveSpeedView : UIView


@property(nonatomic,getter = isVisible) BOOL visible;

@property(nonatomic,retain) IBOutlet MEXWaveFxView* smallVenueWave;
@property(nonatomic,retain) IBOutlet MEXWaveFxView* mediumVenueWave;
@property(nonatomic,retain) IBOutlet MEXWaveFxView* largeVenueWave;

@property(nonatomic,retain) IBOutlet UIButton* btnFun;
@property(nonatomic,retain) IBOutlet UIButton* btnGig;
@property(nonatomic,retain) IBOutlet UIButton* btnStadium;

@property(nonatomic,retain) IBOutlet UILabel* lblStepOne;
@property(nonatomic,retain) IBOutlet UILabel* lblStepTwo;
@property(nonatomic,retain) IBOutlet UILabel* lblStepThree;

@property(nonatomic,retain) IBOutlet UILabel* lblSmall;
@property(nonatomic,retain) IBOutlet UILabel* lblMedium;
@property(nonatomic,retain) IBOutlet UILabel* lblLarge;

-(IBAction)didSelectWaveSpeed:(id)sender;
-(void)didBecomeActive;
-(void)didEnterBackground;
-(void)startAnimatingCurrentSelection;
-(void)stopAnimating;
@end