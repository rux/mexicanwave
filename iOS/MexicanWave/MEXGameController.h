//
//  MEXGameController.h
//  MexicanWave
//
//  Created by Daniel Anderton on 15/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MEXGameController : NSObject
//The view that holds the bubble and label which is shown where user incorrectly taps

@property (retain, nonatomic) IBOutlet UIView *errorView; 
@property (retain, nonatomic) IBOutlet UILabel *errorMessage; //The label of Error message to show
@property (retain, nonatomic) IBOutlet UIImageView *gameModeSprite; //The Sprite image to move when the tap gesture is successful.
@property (nonatomic) BOOL canWave; //Boolean to check if we are allowed to animate. (if YES its the correct time to animate sprite)

@property (retain, nonatomic) IBOutlet UILabel *lblHighscore; //The label of Error message to show
@property (retain, nonatomic) IBOutlet UILabel *lblCurrentScore; //The label of Error message to show


-(void)didTapDisplay;

@end
