//
//  ProgressView.h
//  MexicanWave
//
//  Created by Daniel Anderton on 09/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    kProgressModeSpin,
    kProgressModeImage,
}ProgressModes;

@interface ProgressView : UIView

@property(nonatomic,retain) NSString* titleText;
@property(nonatomic,retain) UIImage* customImage;

-(void)showWithAnimation:(BOOL)animate;
-(void)hideWithAnimatiom:(BOOL)animate;
-(void)hideWithAnimatiom:(BOOL)animate withDelay:(NSTimeInterval)delay;
-(void)changeMode:(ProgressModes)mode;
@end
