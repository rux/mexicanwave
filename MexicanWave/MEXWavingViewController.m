//
//  MEXWavingViewController.m
//  MexicanWave
//
//  Created by Tom York on 29/02/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "MEXWavingViewController.h"
#import "MEXWaveModel.h"
#import "MEXCalibrationModel.h"
#import "MEXWaveFxView.h"

@implementation MEXWavingViewController

@synthesize waveView;
@synthesize waveModel, calibrationModel;

- (MEXWaveModel*)waveModel {
    if(!waveModel) {
        waveModel = [[MEXWaveModel alloc] init];
    }
    return waveModel;
}

- (MEXCalibrationModel*)calibrationModel {
    if(!calibrationModel) {
        calibrationModel = [[MEXCalibrationModel alloc] init];
    }
    return calibrationModel;
}

#pragma mark - UI actions

- (IBAction)didTapSmallAudienceButton:(id)sender {
    self.waveModel.crowdType = kMEXCrowdTypeSmallGroup;
}

- (IBAction)didTapGigButton:(id)sender {
    self.waveModel.crowdType = kMEXCrowdTypeStageBased;    
}

- (IBAction)didTapStadiumButton:(id)sender {
    self.waveModel.crowdType = kMEXCrowdTypeStadium;
}

- (IBAction)didTapCalibrationButton:(id)sender {
    [self.calibrationModel startCalibratingWithErrorPercentage:0 timeout:4.0 completionBlock:^(float deviceHeading, NSError* error) {
        self.waveModel.deviceHeadingInDegreesEastOfNorth = [self.calibrationModel headingInDegreesEastOfNorth];
    }];
}

#pragma mark - Wave trigger

- (void)didWave:(NSNotification*)note {
    // TODO:
}

#pragma mark - Lifecycle

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MEXWaveModelDidWaveNotification object:nil];
    [waveModel release];
    [calibrationModel release];
    [waveView release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.waveView setAllLampIntensities:1.0f animated:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didWave:) name:MEXWaveModelDidWaveNotification object:nil];
        
    NSArray* locations = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(100, 100)],nil];
    NSArray* scaleFactors = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1.0f],nil];

    
    [self.waveView configureLampsWithLocations:locations scaleFactors:scaleFactors];    
    [self.waveView setAllLampIntensities:0 animated:NO];
    
    // Set crowd type on view from model
    self.waveModel.crowdType; // TODO:
}
 
- (void)viewDidUnload {
    [super viewDidUnload];
    self.waveView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MEXWaveModelDidWaveNotification object:nil];
}

#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

@end
