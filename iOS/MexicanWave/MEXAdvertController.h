//
//  MEXAdvertController.h
//  MexicanWave
//
//  Created by Tom York on 25/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MEXAdvertController : NSObject

@property (nonatomic,retain) IBOutlet UIButton* advertButton;
@property (nonatomic,retain) IBOutlet UILabel* hintTextLabel;
- (IBAction)didTapAdvertButton:(id)sender;

@end
