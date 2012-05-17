//
//  MEXAdvertController.h
//  MexicanWave
//
//  Created by Tom York on 25/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MEXAdvertController : NSObject

@property (nonatomic,retain) IBOutlet UIImageView* clearBackgound; // The UIImageView that covers the background on launch
@property (nonatomic,retain) IBOutlet UIButton* advertButton; //Button for advert
@property (nonatomic,retain) IBOutlet UILabel* hintTextLabel;  // The hint text shown to user on launch
- (IBAction)didTapAdvertButton:(id)sender;

@end
