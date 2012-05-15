//
//  SpriteView.h
//  MexicanWave
//
//  Created by Daniel Anderton on 14/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpriteView : UIView

@property(nonatomic,retain) UIImageView* sprite;
@property(nonatomic,retain) UIImage* spriteImage;
-(void)animateBounceWithCycleTime:(NSTimeInterval)cycleTime activeTime:(NSTimeInterval)activeTime phase:(float)phase;

@end
