//
//  MEXWavingViewController.h
//  MexicanWave
//
//  Created by Tom York on 29/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsView.h"
#import "CameraSessionController.h"
#import "MEXGameController.h"
@class MEXWaveFxView;
@class MEXWaveModel;
@class MEXAdvertController;

@interface MEXWavingViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic,retain) MEXWaveModel* waveModel;
@property (nonatomic,getter=isVibrationOnWaveEnabled) BOOL vibrationOnWaveEnabled;
@property (nonatomic,getter=isSoundOnWaveEnabled) BOOL soundOnWaveEnabled;
@property (nonatomic,getter=isPaused) BOOL paused;
@property (nonatomic,getter=isGameMode) BOOL gameMode;

@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UIView *videoView;
@property (retain, nonatomic) IBOutlet MEXWaveFxView* waveView;
@property (retain, nonatomic) IBOutlet SettingsView *settingView;
@property (retain, nonatomic) IBOutlet UIImageView *tabImageView;
@property (retain, nonatomic) IBOutlet UIView *whiteFlashView;
@property (retain, nonatomic) IBOutlet MEXAdvertController* advertController;
@property (retain, nonatomic) IBOutlet MEXGameController* gameController;


- (IBAction)didTapGrabber:(id)sender;
- (void)didChangeCrowdType:(NSNotification*)note;
- (void)pause;
- (void)resume;
-(void)startWave;
-(void)didTapLegelButton:(id)sender;
@end
