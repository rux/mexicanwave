//
//  UserGuideView.h
//  MexicanWave
//
//  Created by Daniel Anderton on 24/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    kBtnFunTag = 200,
    kBtnGigTag = 201,
    kBtnStaduimTag = 202,
} kBtnTags;
NSString* const kSpeedSegementDidChange;

@interface UserGuideView : UIView

@property(nonatomic, getter = isPaused) BOOL pause;


@property(nonatomic,retain) IBOutlet UIView* funContainer;
@property(nonatomic,retain) IBOutlet UIView* gigContainer;
@property(nonatomic,retain) IBOutlet UIView* stadiumContainer;

@property(nonatomic,retain) IBOutlet UIButton* btnFun;
@property(nonatomic,retain) IBOutlet UIButton* btnGig;
@property(nonatomic,retain) IBOutlet UIButton* btnStadium;

@property(nonatomic,retain) IBOutlet UILabel* lblStepOne;
@property(nonatomic,retain) IBOutlet UILabel* lblStepTwo;
@property(nonatomic,retain) IBOutlet UILabel* lblStepThree;


-(IBAction)didSelectWaveSpeed:(id)sender;

@end
