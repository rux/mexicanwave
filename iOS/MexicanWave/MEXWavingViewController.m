//
//  MEXWavingViewController.m
//  MexicanWave
//
//  Created by Tom York on 29/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "MEXWavingViewController.h"
#import "MEXWaveModel.h"
#import "MEXWaveFxView.h"
#import "MEXCrowdTypeSelectionControl.h"
#import "MEXLegacyTorchController.h"            // TODO: Remove this once support for iOS 4.x is not a concern.
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "OmnitureLogging.h"
#import "SharePhotoViewController.h"

#define kTorchOnTime 0.25f
#define kModelKeyPathForPeriod @"wavePeriodInSeconds"
#define kModelKeyPathForPhase @"wavePhase"
#define kModelKeyPathForPeaks @"numberOfPeaks"

@interface MEXWavingViewController ()
@property (nonatomic,retain) MEXLegacyTorchController* legacyTorchController;
@property (nonatomic) SystemSoundID waveSoundID;
-(void)bounceAnimation;
-(void)setTorchMode:(AVCaptureTorchMode)newMode;
@end


@implementation MEXWavingViewController
@synthesize videoView;
@synthesize containerView;
@synthesize waveView;
@synthesize settingView;
@synthesize tabImageView;
@synthesize whiteFlashView;
@synthesize waveModel;
@synthesize vibrationOnWaveEnabled, soundOnWaveEnabled;
@synthesize legacyTorchController;
@synthesize waveSoundID,paused;

- (MEXWaveModel*)waveModel {
    if(!waveModel) {
        waveModel = [[MEXWaveModel alloc] init];
        [waveModel addObserver:self forKeyPath:kModelKeyPathForPhase options:NSKeyValueObservingOptionNew context:NULL];
        [waveModel addObserver:self forKeyPath:kModelKeyPathForPeriod options:NSKeyValueObservingOptionNew context:NULL];
        [waveModel addObserver:self forKeyPath:kModelKeyPathForPeaks options:NSKeyValueObservingOptionNew context:NULL];
    }
    return waveModel;
}

#pragma mark - UI actions

- (IBAction)didTapTakePhoto:(id)sender {
    
    [[CameraSessionController sharedCameraController] capturePhotoWithCompletion:^{
        if(![[CameraSessionController sharedCameraController] isCapturedImage]){
            return;
        }
        SharePhotoViewController* photoView = [[SharePhotoViewController alloc]init];
        photoView.takenphoto = [[CameraSessionController sharedCameraController] capturedImage];
        UINavigationController* navController = [[UINavigationController alloc]initWithRootViewController:photoView];
        [self presentModalViewController:navController animated:YES];
        [navController release];
        [photoView release];
    }];
  
}

- (void)didChangeCrowdType:(NSNotification*)note{
    if(![note object]){
        return;
    }
    NSNumber* newSelection = (NSNumber*)[note object];
    const NSInteger selection = [newSelection integerValue];
    
    switch (selection) {
        case 0:
            self.waveModel.crowdType = kMEXCrowdTypeSmallGroup;
            break;
            
        case 1:
            self.waveModel.crowdType = kMEXCrowdTypeStageBased;    
            break;

        case 2:
            self.waveModel.crowdType = kMEXCrowdTypeStadium;
            break;
        default:
            break;
    }
}


#pragma mark - Torch handling

- (void)torchOff {
    if(self.legacyTorchController) {
        // iOS 4.x
        [self.legacyTorchController torchOff];
        return;        
    }
    // iOS 5+
    [self setTorchMode:AVCaptureTorchModeOff];
}

- (void)torchOn { 
    if(self.legacyTorchController) {
        // iOS 4.x
        [self.legacyTorchController torchOn];
    }
    else {
        // iOS 5+
        [self setTorchMode:AVCaptureTorchModeOn];
    }
        
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, kTorchOnTime * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self torchOff];
    });
}

- (void)setTorchMode:(AVCaptureTorchMode)newMode {    
    AVCaptureDevice* backCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if([backCamera isTorchAvailable] && [backCamera isTorchModeSupported:newMode] && [backCamera torchMode] != newMode) {
        if([backCamera lockForConfiguration:nil]) {
            [backCamera setTorchMode:newMode];
            [backCamera unlockForConfiguration];
        }
    }
}

#pragma mark - App lifecycle

- (void)pause {
    self.paused = YES;
    //stop filming
    [[CameraSessionController sharedCameraController] pauseDisplay];    
    // Turn off the torch (just in case)
    [self torchOff];
    // Suspend the model
    [self.waveModel pause];
   
}

- (void)resume {
    
       
   // Refetch our settings preferences, they may have changed while we were in the background.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	self.vibrationOnWaveEnabled = [defaults boolForKey:kUserDefaultKeyVibration];    
    self.soundOnWaveEnabled = [defaults boolForKey:kUserDefaultKeySound];
    self.waveModel.crowdType = [defaults integerForKey:MEXWaveSpeedSettingsKey];
    // Start running again
    [self.waveModel resume];

    self.paused = NO;

}

#pragma mark - Notifications

// Handles behaviour on wave trigger, i.e. wave has just passed our bearing
- (void)didWave:(NSNotification*)note {
    if(!self.isViewLoaded) {
        return;
    }
    
    // Flash the torch
    [self torchOn];

    // Vibrate
    if(self.isVibrationOnWaveEnabled) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    
    // Play sound
    if(self.isSoundOnWaveEnabled) {
        AudioServicesPlaySystemSound(self.waveSoundID);
    }

    if(!self.isPaused){
        const float duration = (self.waveModel.crowdType == 2) ? 0.5 : 0.2;
        //animate the screen flash
        [UIView animateWithDuration:duration animations:^{
            self.whiteFlashView.alpha = 1; 
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:duration animations:^{
                self.whiteFlashView.alpha = 0;            
            }];
        }];
    }
}

#pragma mark - Controller lifecycle

- (void)awakeFromNib {
    if(!self.legacyTorchController && [MEXLegacyTorchController isLegacySystem]) {
        self.legacyTorchController = [[[MEXLegacyTorchController alloc] init] autorelease];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [waveModel pause];
    [videoView release];
    [waveModel removeObserver:self forKeyPath:kModelKeyPathForPhase];
    [waveModel removeObserver:self forKeyPath:kModelKeyPathForPeriod];
    [waveModel removeObserver:self forKeyPath:kModelKeyPathForPeaks];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    AudioServicesDisposeSystemSoundID(waveSoundID);
    [waveModel release];
    [waveView release];
    [legacyTorchController release];
    [containerView release];
    [settingView release];
    [tabImageView release];
    [whiteFlashView release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setContainerView:nil];
    [self setSettingView:nil];
    [self setTabImageView:nil];
    [self setWhiteFlashView:nil];
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self torchOff];
    
    AudioServicesDisposeSystemSoundID(waveSoundID);
    self.waveSoundID = 0;
    
    self.waveView = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self torchOff];
    [self pause];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self resume];    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //restart video capture
    if(![[CameraSessionController sharedCameraController]cameraView]){
        [[CameraSessionController sharedCameraController] setCameraView:self.videoView];
    }
    [[CameraSessionController sharedCameraController] resumeDisplay];
}

- (void)viewDidLoad {
    //animate in to hint to the user whats behind the main view
    [self bounceAnimation];

    //prevent the phone from auto-locking and dimming
    [UIApplication sharedApplication].idleTimerDisabled = YES;
        
    [[OmnitureLogging sharedInstance] postEventAppFinishedLaunching];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didWave:) name:MEXWaveModelDidWaveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resume) name:kSettingsDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeCrowdType:) name:kSpeedSegementDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resume) name:UIApplicationDidBecomeActiveNotification object:nil];
    // Load in the wave sound.
    AudioServicesCreateSystemSoundID((CFURLRef)[[NSBundle mainBundle] URLForResource:@"clapping" withExtension:@"caf"], &waveSoundID);

    UIPanGestureRecognizer* swipeLeft = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(didRecievePanGestureLeft:)];

    UIPanGestureRecognizer* swipeRight = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(didRecievePanGestureRight:)];
    
    [self.tabImageView addGestureRecognizer:swipeRight];
    [self.containerView addGestureRecognizer:swipeLeft];
      
    [swipeRight release];
    [swipeLeft release];

    [super viewDidLoad];

}

#pragma mark Gesture Recognizer callbacks
-(void)didRecievePanGestureLeft:(UIPanGestureRecognizer*)recognizer{
    
    CGFloat offset = [recognizer translationInView:self.containerView].x;    
    CGFloat velocity = [recognizer velocityInView:self.containerView].x;
   
    //we only want the view to move left
    //there was an occasion where if the user gestured too last we got stuck on the view. to fix that we just animate back
    if(offset>0){
        [UIView animateWithDuration:0.2 animations:^{
            self.containerView.frame = CGRectMake(0, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);}];
            return;
    }
    
    [self pause];

    //move the view with the correct offset - we want to start at minus the size of view so that

    self.containerView.frame = CGRectMake(offset, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);
       
    if(recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed){

        //if the velocity is high we can assue it was a flick and animate all the way across its minus because we are going left
        if(velocity<-1000){
            [UIView animateWithDuration:0.2 animations:^{
                self.containerView.frame = CGRectMake(-320, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);}];
            [[OmnitureLogging sharedInstance] postEventSettingsViewVisible];
            return;
        }
        //if not compare the current offset in relation to the view - if over half way snap to the side
        offset = (offset> -160) ? 0 : -320;
        
        //if the offset is off the view post that the user has seeing the settings view else we can continue flashing the view        
        [UIView animateWithDuration:0.2 animations:^{
            self.containerView.frame = CGRectMake(offset, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);}completion:^(BOOL finished) {
                if(offset == -320){
                    [[OmnitureLogging sharedInstance]postEventSettingsViewVisible];
                }
                else{  
                    [self resume];
                    [[CameraSessionController sharedCameraController] resumeDisplay];
                }
            }];
    }       
}
-(void)didRecievePanGestureRight:(UIPanGestureRecognizer*)recognizer{
    
    CGFloat offset = [recognizer translationInView:self.containerView].x;    
    CGFloat velocity = [recognizer velocityInView:self.containerView].x;
    //we only want the view to move Right
    if(offset<0){
        return;
    }
    
    [self pause];

      NSLog(@"*RIGHT**");
    //move the view with the correct offset - we want to start at minus the size of view so that
    self.containerView.frame = CGRectMake(-320+offset, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);
    
    if(recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed){
        //if the velocity is high we can assue it was a flick and animate all the way across
        if(velocity>1000){
            [UIView animateWithDuration:0.2 animations:^{
                self.containerView.frame = CGRectMake(0, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);}completion:^(BOOL finished) {
                    [self resume];
                    [[CameraSessionController sharedCameraController] resumeDisplay];

                }];
          
            return;
        }
        //if not compare the current offset in relation to the view - if over half way snap to the side- continues animation occordetly
        offset = (offset> 160) ? 0 : -320;

        [UIView animateWithDuration:0.2 animations:^{
            self.containerView.frame = CGRectMake(offset, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);} completion:^(BOOL finished) {
                if(offset == 0) { 
                    [self resume];
                    [[CameraSessionController sharedCameraController] resumeDisplay];

                }
            }];
    }   
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(object != self.waveModel) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    // A wave period change or angle change means we need to update the display.
    [self.waveView animateWithDuration:self.waveModel.wavePeriodInSeconds startingPhase:self.waveModel.wavePhase numberOfPeaks:self.waveModel.numberOfPeaks];
}

#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

-(void)bounceAnimation{
   
    //animate the conatiner view left - and create a bounce like effect  
    CATransform3D resetTransform = CATransform3DMakeTranslation(0, 0, 0);
    
    CATransform3D startTransfom = CATransform3DMakeTranslation(-24, 0, 0);

    CATransform3D middleTransfom = CATransform3DMakeTranslation(-12, 0, 0);

    CATransform3D endTransform = CATransform3DMakeTranslation(-6, 0, 0);

    CAKeyframeAnimation* opacityAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    opacityAnim.values = [NSArray arrayWithObjects:[NSValue valueWithCATransform3D:startTransfom],
                          [NSValue valueWithCATransform3D:resetTransform],
                          [NSValue valueWithCATransform3D:middleTransfom],
                          [NSValue valueWithCATransform3D:resetTransform],
                          [NSValue valueWithCATransform3D:endTransform],
                          [NSValue valueWithCATransform3D:resetTransform],nil];
    
    opacityAnim.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.16667],[NSNumber numberWithFloat:0.33],[NSNumber numberWithFloat:0.50],[NSNumber numberWithFloat:0.666],[NSNumber numberWithFloat:0.8333],[NSNumber numberWithFloat:1],nil];
    opacityAnim.duration = 1.0;
    
    [self.containerView.layer addAnimation:opacityAnim forKey:@"bounce"];

}
#pragma mark Yell Advert 


- (IBAction)didTapGrabber:(id)sender {
    [self bounceAnimation];
}
@end
