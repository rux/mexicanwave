//
//  MEXGameController.h
//  MexicanWave
//
//  Created by Daniel Anderton on 15/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MEXGameController : NSObject

@property (retain, nonatomic) IBOutlet UIView *errorView;
@property (retain, nonatomic) IBOutlet UIImageView *gameModeSprite;
@property (nonatomic) BOOL canAnimate;
@property (nonatomic) BOOL canWave;
@property (nonatomic,getter = isShowingError) BOOL showingError;

@property (nonatomic, getter = isAnimating) BOOL animating;

-(void)didTapDisplay;

@end
