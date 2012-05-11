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
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "UsageMetrics.h"
#import "MEXAdvertController.h"
#import "GenericTextViewController.h"

#define kTorchOnTime 0.25f
#define kModelKeyPathForPeriod @"wavePeriodInSeconds"
#define kModelKeyPathForPhase @"wavePhase"
#define kModelKeyPathForPeaks @"numberOfPeaks"
#define kShownHintToUser @"kShownHintToUser"

@interface MEXWavingViewController ()
@property (nonatomic) SystemSoundID waveSoundID;
@property (nonatomic) BOOL waveVisible;
-(void)startWave;
-(void)bounceAnimation;
-(void)setTorchMode:(AVCaptureTorchMode)newMode;
-(void)didRecieveLegalNotification:(NSNotification*)note;
- (void)mexicanConfetti;
@end


@implementation MEXWavingViewController
@synthesize videoView;
@synthesize confettiView;
@synthesize containerView;
@synthesize waveView;
@synthesize settingView;
@synthesize tabImageView;
@synthesize whiteFlashView;
@synthesize waveModel;
@synthesize advertController;
@synthesize vibrationOnWaveEnabled, soundOnWaveEnabled;
@synthesize waveSoundID,paused;
@synthesize waveVisible,gameMode;


#pragma mark - Controller lifecycle

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
    [containerView release];
    [settingView release];
    [tabImageView release];
    [whiteFlashView release];
    [advertController release];
    [confettiView release];
    [super dealloc];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self torchOff];
    [self pause];
    //stop filming
    [[CameraSessionController sharedCameraController] pauseDisplay];   
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self resume];    
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:kShownHintToUser]){
        //animate in to hint to the user whats behind the main view
        [self bounceAnimation];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShownHintToUser];
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set up camera session
    [[CameraSessionController sharedCameraController] setCameraView:self.videoView];
    [[CameraSessionController sharedCameraController] setAutoFocusEnabled:YES];
    
    
    //prevent the phone from auto-locking and dimming
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didWave:) name:MEXWaveModelDidWaveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeCrowdType:) name:kSpeedSegementDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRecieveLegalNotification:) name:@"Legal" object:nil];
    
    // Load in the wave sound.
    AudioServicesCreateSystemSoundID((CFURLRef)[[NSBundle mainBundle] URLForResource:@"clapping" withExtension:@"caf"], &waveSoundID);
    
    //gestures to allow the user to swipe to back and forth the settings screen
    UIPanGestureRecognizer* swipeLeft = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(didRecievePanGestureLeft:)];
    UIPanGestureRecognizer* swipeRight = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(didRecievePanGestureRight:)];
    
    [self.tabImageView addGestureRecognizer:swipeRight];
    [self.containerView addGestureRecognizer:swipeLeft];
    
    [swipeRight release];
    [swipeLeft release];
    
    UITapGestureRecognizer* tapWave = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didCatchTheWave:)];
    tapWave.delegate = self;
    [self.containerView addGestureRecognizer:tapWave];
    [tapWave release];
    
}

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

- (void)didChangeCrowdType:(NSNotification*)note{
    if(![note object]){
        return;
    }
    NSNumber* newSelection = (NSNumber*)[note object];
    const NSInteger selection = [newSelection integerValue];
    
    switch (selection) {
        case 0:
            self.waveModel.venueSize = kMEXVenueSizeSmall;
            break;
            
        case 1:
            self.waveModel.venueSize = kMEXVenueSizeMedium;
            break;

        case 2:
            self.waveModel.venueSize = kMEXVenueSizeLarge;
            break;
        default:
            break;
    }
}

#pragma mark - Torch handling

- (void)torchOff {
      // iOS 5+
    [self setTorchMode:AVCaptureTorchModeOff];
}

- (void)torchOn { 
  
    [self setTorchMode:AVCaptureTorchModeOn];
    
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
    // Turn off the torch (just in case)
    [self torchOff];
    // Suspend the model
    [self.waveModel pause];
    //As the settings view is about to become visible start animating the current speed selection
    [self.settingView.speedView startAnimatingCurrentSelection];
   
}

- (void)resume {
          
    // Refetch our settings preferences, they may have changed while we were in the background.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	self.vibrationOnWaveEnabled = [defaults boolForKey:kUserDefaultKeyVibration];    
    self.soundOnWaveEnabled = [defaults boolForKey:kUserDefaultKeySound];
    self.gameMode = [defaults boolForKey:kUserDefaultKeyGameMode];
    // Start running again
    [self.waveModel resume];

    self.paused = NO;

    //sets up for video capture sessions. Gives the controller the correct view and setttings
    [[CameraSessionController sharedCameraController] resumeDisplay];
    
    //as the main view is now visable stop animating the help guide on the settings view
    [self.settingView.speedView stopAnimating];
    
}

#pragma mark - Notifications

// Handles behaviour on wave trigger, i.e. wave has just passed our bearing
- (void)didWave:(NSNotification*)note {
    if(!self.isViewLoaded) {
        return;
    }
    if(self.isPaused){
        return;
    }
    if(!self.isGameMode){
        [self startWave];
        return;
    }
    
    self.waveVisible = YES;

    double delayInSeconds = (self.waveModel.venueSize == kMEXVenueSizeLarge) ? 1 : 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.waveVisible = NO;
    });
    
}

-(void)startWave{
    const float duration = (self.waveModel.venueSize == kMEXVenueSizeLarge) ? 0.55 : 0.35;
    //animate the screen flash
    [UIView animateWithDuration:duration animations:^{
        self.whiteFlashView.alpha = 1; 
    }completion:^(BOOL finished) {
        
        [UIView animateWithDuration:duration animations:^{
            self.whiteFlashView.alpha = 0;            
        }completion:^(BOOL finished) {
        }];
        
    }];
    
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

- (void)viewDidUnload {
    [self setConfettiView:nil];
    [super viewDidUnload];

    self.containerView = nil;
    self.settingView = nil;
    self.tabImageView = nil;
    self.whiteFlashView = nil;
    self.advertController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self torchOff];
    
    [[CameraSessionController sharedCameraController] setCameraView:nil];
    AudioServicesDisposeSystemSoundID(waveSoundID);
    self.waveSoundID = 0;
    self.waveView = nil;
}

#pragma mark Gesture Recognizer callbacks
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIButton class]]) {
        // we touched a button
        return NO; // ignore the touch
    }
    return YES; // handle the touch
}

-(void)didCatchTheWave:(UITapGestureRecognizer*)tap{
    
    if (self.waveVisible) {
        [self startWave];
        [self mexicanConfetti];
    }
    
}

- (void)mexicanConfetti {
	int n = 15;
	int i;
	
	for (i = 0; i<n; i++) {
		CALayer *l  = [CALayer layer];
		l.contents = (id)[[UIImage imageNamed:@"mexican.png"] CGImage];
		l.frame = CGRectMake(0, 0, 36, 22);
		[self.confettiView.layer addSublayer:l];
		
		float duration = ((float)(arc4random() % 100) / 55.0f) + 0.1f;
		
		CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
		animationGroup.delegate = self;
		animationGroup.duration = duration;
		
		CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
		CGPoint startPoint = CGPointMake(arc4random() % 10, arc4random() % 30);
        NSLog(@"%f",startPoint.x);
		positionAnimation.fromValue = [NSValue valueWithCGPoint:startPoint];
		
		float x = startPoint.x - ((10 - startPoint.x ) * 0.4f);
		float y = (startPoint.y - ((20 - startPoint.y) * 0.4f)) ;
		CGPoint endPoint = CGPointMake(x, y);
		
		positionAnimation.toValue = [NSValue valueWithCGPoint:endPoint];
		positionAnimation.timingFunction = [CAMediaTimingFunction functionWithName:@"easeIn"]; 
		positionAnimation.duration = duration;
		
		CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		opacityAnimation.fromValue = [NSNumber numberWithFloat:0.7f];
		opacityAnimation.toValue = [NSNumber numberWithFloat:0.0f];
		opacityAnimation.duration = duration - 0.1;
		opacityAnimation.fillMode = kCAFillModeForwards;
		l.opacity = 0;
		
		CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
		rotateAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
		rotateAnimation.toValue = [NSNumber numberWithFloat:arc4random() % 4 + 7];
		rotateAnimation.duration = duration;
		
		CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
		scaleAnimation.fromValue = [NSNumber numberWithFloat:0.6f];
		scaleAnimation.toValue = [NSNumber numberWithFloat:((arc4random() % 70) / 40.0f) + 1.0f];
		scaleAnimation.duration = duration;
		
		animationGroup.animations = [NSArray arrayWithObjects:positionAnimation, opacityAnimation, rotateAnimation, scaleAnimation, nil];
		animationGroup.delegate = self;
		// Add the animation, overriding the implicit animation.
		
		[animationGroup setValue:l forKey:@"animatedLayer"];
		[l addAnimation:animationGroup forKey:@"confetti"];
	}
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	CALayer *l = [anim valueForKey:@"animatedLayer"];
	if (l) {
		[l removeFromSuperlayer];
		//[confettiLayers removeObject:l];		
	}
}



-(void)didRecievePanGestureLeft:(UIPanGestureRecognizer*)recognizer{
    
    CGFloat offset = [recognizer translationInView:self.containerView].x;    
    CGFloat velocity = [recognizer velocityInView:self.containerView].x;
   
    //we only want the view to move left
    //there was an occasion where if the user gestured too last we got stuck on the view. to fix that we just animate back
    if(offset>0){
        [UIView animateWithDuration:0.2 animations:^{
            self.containerView.frame = CGRectMake(0, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);}];
            [self resume];
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
            
            return;
        }
        //if not compare the current offset in relation to the view - if over half way snap to the side
        const NSInteger finalOffset = (offset> -160) ? 0 : -320;
        
        //if the offset is off the view post that the user has seeing the settings view else we can continue flashing the view        
        [UIView animateWithDuration:0.2 animations:^{
            self.containerView.frame = CGRectMake(finalOffset, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);}completion:^(BOOL finished) {
                if(finalOffset != -320){
                    [self resume];
                }
            }];
    }       
}
-(void)didRecievePanGestureRight:(UIPanGestureRecognizer*)recognizer{
    
    CGFloat offset = [recognizer translationInView:self.containerView].x;    
    CGFloat velocity = [recognizer velocityInView:self.containerView].x;
    //we only want the view to move Right
    if(offset<0){
        [self resume];
        return;
    }
    
    [self pause];

    //move the view with the correct offset - we want to start at minus the size of view so that
    self.containerView.frame = CGRectMake(-320+offset, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);
    
    if(recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed){
        //if the velocity is high we can assue it was a flick and animate all the way across
        if(velocity>1000){
            [UIView animateWithDuration:0.2 animations:^{
                self.containerView.frame = CGRectMake(0, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);}completion:^(BOOL finished) {
                    [self resume];

                }];
          
            return;
        }
        //if not compare the current offset in relation to the view - if over half way snap to the side- continues animation occordetly
        const NSInteger finalOffset = (offset> 160) ? 0 : -320;

        [UIView animateWithDuration:0.2 animations:^{
            self.containerView.frame = CGRectMake(finalOffset, 0.0f, self.containerView.frame.size.width, self.containerView.frame.size.height);} completion:^(BOOL finished) {
                if(finalOffset == 0) { 
                    [self resume];

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
    
    CATransform3D startTransfom = CATransform3DMakeTranslation(-60, 0, 0);

    CATransform3D middleTransfom = CATransform3DMakeTranslation(-30, 0, 0);

    CATransform3D endTransform = CATransform3DMakeTranslation(-15, 0, 0);

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

-(void)didRecieveLegalNotification:(NSNotification*)note{
    GenericTextViewController* text = [[GenericTextViewController alloc]init];
    text.textToShow = NSLocalizedString(@"Legal Text", @"The text shown in the Legal section");
    text.title = NSLocalizedString(@"Legal", @"The title text shown in the Legal view");
    
    UINavigationController* navController = [[UINavigationController alloc]initWithRootViewController:text];
    UIBarButtonItem* cancel =[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:text action:@selector(didTapCancel)];
    text.navigationItem.leftBarButtonItem = cancel;
    [self presentModalViewController:navController animated:YES];
    [text release];
    [navController release];
    [cancel release];
}

- (IBAction)didTapGrabber:(id)sender {
    if(self.isPaused){
        return;
    }
    [self bounceAnimation];
}



@end
