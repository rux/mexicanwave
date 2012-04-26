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
} kWaveSelection;
NSString* const kSpeedSegementDidChange;

@interface UserGuideView : UIView



@property(nonatomic,retain) IBOutlet MEXWaveFxView* funContainer;
@property(nonatomic,retain) IBOutlet MEXWaveFxView* gigContainer;
@property(nonatomic,retain) IBOutlet MEXWaveFxView* stadiumContainer;

@property(nonatomic,retain) IBOutlet UIButton* btnFun;
@property(nonatomic,retain) IBOutlet UIButton* btnGig;
@property(nonatomic,retain) IBOutlet UIButton* btnStadium;

@property(nonatomic,retain) IBOutlet UILabel* lblStepOne;
@property(nonatomic,retain) IBOutlet UILabel* lblStepTwo;
@property(nonatomic,retain) IBOutlet UILabel* lblStepThree;

@property(nonatomic,retain) IBOutlet UILabel* lblFun;
@property(nonatomic,retain) IBOutlet UILabel* lblGig;
@property(nonatomic,retain) IBOutlet UILabel* lblStadium;

-(IBAction)didSelectWaveSpeed:(id)sender;
-(void)startWaveWithTag:(kWaveSelection)newSelection;
@end