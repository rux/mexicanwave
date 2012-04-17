//
//  MEXWavingViewController.h
//  MexicanWave
//
//  Created by Tom York on 29/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsView.h"
#import "VideoPreviewView.h"

@class MEXWaveFxView;
@class MEXWaveModel;

@interface MEXWavingViewController : UIViewController

@property (nonatomic,retain) MEXWaveModel* waveModel;
@property (nonatomic,getter=isVibrationOnWaveEnabled) BOOL vibrationOnWaveEnabled;
@property (nonatomic,getter=isSoundOnWaveEnabled) BOOL soundOnWaveEnabled;
@property (nonatomic,getter=isPaused) BOOL paused;

@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet VideoPreviewView *videoView;
@property (nonatomic,retain) IBOutlet MEXWaveFxView* waveView;
@property (retain, nonatomic) IBOutlet SettingsView *settingView;
@property (retain, nonatomic) IBOutlet UIImageView *tabImageView;
@property (retain, nonatomic) IBOutlet UIView *whiteFlashView;
- (IBAction)didTapTakePhoto:(id)sender;

- (void)didChangeCrowdType:(NSNotification*)note;
- (void)pause;
- (void)resume;
@end
