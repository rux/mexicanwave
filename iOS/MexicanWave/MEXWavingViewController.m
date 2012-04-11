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

#define kTorchOnTime 0.25f
#define kModelKeyPathForPeriod @"wavePeriodInSeconds"
#define kModelKeyPathForPhase @"wavePhase"
#define kModelKeyPathForPeaks @"numberOfPeaks"


@interface MEXWavingViewController ()
@property (nonatomic,retain) MEXLegacyTorchController* legacyTorchController;
@property (nonatomic) SystemSoundID waveSoundID;
-(void)animateHintToUser;
-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view;
-(void)setTorchMode:(AVCaptureTorchMode)newMode;
@end


@implementation MEXWavingViewController

@synthesize containerView;
@synthesize waveView;
@synthesize crowdTypeSelectionControl;
@synthesize settingView;
@synthesize waveModel;
@synthesize vibrationOnWaveEnabled, soundOnWaveEnabled;
@synthesize legacyTorchController;
@synthesize waveSoundID;

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

- (IBAction)didChangeCrowdType:(id)sender {
    switch ([(MEXCrowdTypeSelectionControl*)sender selectedSegment]) {
        case MEXCrowdTypeSelectionSegmentLeft:
            self.waveModel.crowdType = kMEXCrowdTypeSmallGroup;
            break;
            
        case MEXCrowdTypeSelectionSegmentMiddle:
            self.waveModel.crowdType = kMEXCrowdTypeStageBased;    
            break;

        case MEXCrowdTypeSelectionSegmentRight:
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
    // Turn off the torch (just in case)
    [self torchOff];
    // Suspend the model
    [self.waveModel pause];
}

- (void)resume {
    // Refetch our settings preferences, they may have changed while we were in the background.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	self.vibrationOnWaveEnabled = [defaults boolForKey:@"vibration_preference"];    
    self.soundOnWaveEnabled = [defaults boolForKey:@"sound_preference"];
    
    // Start running again
    [self.waveModel resume];
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
    [waveModel removeObserver:self forKeyPath:kModelKeyPathForPhase];
    [waveModel removeObserver:self forKeyPath:kModelKeyPathForPeriod];
    [waveModel removeObserver:self forKeyPath:kModelKeyPathForPeaks];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MEXWaveModelDidWaveNotification object:nil];
    AudioServicesDisposeSystemSoundID(waveSoundID);
    [waveModel release];
    [waveView release];
    [crowdTypeSelectionControl release];
    [legacyTorchController release];
    [containerView release];
    [settingView release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didWave:) name:MEXWaveModelDidWaveNotification object:nil];
    
    // Set crowd type on view from model
    self.crowdTypeSelectionControl.selectedSegment = (MEXCrowdTypeSelectionSegment)self.waveModel.crowdType;
    
    // Load in the wave sound.
    AudioServicesCreateSystemSoundID((CFURLRef)[[NSBundle mainBundle] URLForResource:@"clapping" withExtension:@"caf"], &waveSoundID);

    UISwipeGestureRecognizer* swipeLeft = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(didRecieveSwipeLeftGesture:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.containerView addGestureRecognizer:swipeLeft];
    [swipeLeft release];

    UISwipeGestureRecognizer* swipeRight = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(didRecieveSwipeRightGesture:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.settingView addGestureRecognizer:swipeRight];
    [swipeRight release];
    
    [self animateHintToUser];

}

-(void)didRecieveSwipeLeftGesture:(UISwipeGestureRecognizer*)recognizer{
    if(recognizer.state == UIGestureRecognizerStateEnded){
        [UIView animateWithDuration:0.2 animations:^{
            self.containerView.frame = CGRectMake(-320.0f, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);}];

      }   
}
-(void)didRecieveSwipeRightGesture:(UISwipeGestureRecognizer*)recognizer{
    
    if(recognizer.state == UIGestureRecognizerStateEnded){
        [UIView animateWithDuration:0.2 animations:^{
            self.containerView.frame = CGRectMake(0.0f, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);}];
        
    }   
}


- (void)viewDidUnload {
    [self setContainerView:nil];
    [self setSettingView:nil];
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MEXWaveModelDidWaveNotification object:nil];

    [self torchOff];

    AudioServicesDisposeSystemSoundID(waveSoundID);
    self.waveSoundID = 0;

    self.waveView = nil;
    self.crowdTypeSelectionControl = nil;
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
-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    //take the new anchor point and set it - reset the postion back to its original place. 
    //(changing the anchor point also changed the location of the view.)
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

-(void)animateHintToUser{
   
       
    CATransform3D shiftedOnScreenTransform = CATransform3DMakeTranslation(0, 0, 0);
    
    CATransform3D startTransfom = CATransform3DMakeTranslation(-20, 0, 0);

    CATransform3D middleTransfom = CATransform3DMakeTranslation(-10, 0, 0);

    CATransform3D endTransform = CATransform3DMakeTranslation(-5, 0, 0);

    CAKeyframeAnimation* opacityAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    opacityAnim.values = [NSArray arrayWithObjects:[NSValue valueWithCATransform3D:startTransfom],
                          [NSValue valueWithCATransform3D:shiftedOnScreenTransform],
                          [NSValue valueWithCATransform3D:middleTransfom],
                          [NSValue valueWithCATransform3D:shiftedOnScreenTransform],
                          [NSValue valueWithCATransform3D:endTransform],
                          [NSValue valueWithCATransform3D:shiftedOnScreenTransform],nil];
    
    opacityAnim.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.16667],[NSNumber numberWithFloat:0.33],[NSNumber numberWithFloat:0.50],[NSNumber numberWithFloat:0.666],[NSNumber numberWithFloat:0.8333],[NSNumber numberWithFloat:1],nil];
    opacityAnim.duration = 1.0;
    
    [self.containerView.layer addAnimation:opacityAnim forKey:@"bounce"];

}


@end
