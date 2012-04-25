//
//  UserGuideView.m
//  MexicanWave
//
//  Created by Daniel Anderton on 24/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "UserGuideView.h"
#import "QuartzCore/QuartzCore.h"

NSString* const kSpeedSegementDidChange = @"kSpeedSegementDidChange";

@interface UserGuideView()

-(void)commonInitialisation;
@property(nonatomic) NSInteger currentSelection;
@end

@implementation UserGuideView
@synthesize pause,currentSelection;
@synthesize gigContainer,funContainer,stadiumContainer;
@synthesize btnFun,btnGig,btnStadium;
@synthesize lblStepOne,lblStepThree,lblStepTwo;
-(void)dealloc{
    [lblStepOne release];
    [lblStepThree release];
    [lblStepTwo release];
    [btnGig release];
    [btnFun release];
    [btnStadium release];
    [stadiumContainer release];
    [funContainer release];
    [gigContainer release];
    [super dealloc];
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitialisation];

    }
    return self;
}

-(void)awakeFromNib{
   
        
    
    [self commonInitialisation];
}

-(void)commonInitialisation{
}

-(IBAction)didSelectWaveSpeed:(id)sender{
    if(!sender){
        return;
    }
    UIButton *selected = (UIButton*)sender;
    if(self.currentSelection != selected.tag){
        float animationSpeed;
        switch (selected.tag) {
            case kBtnFunTag:
                animationSpeed = 1.0;
                break;
            case kBtnGigTag:
                animationSpeed = 1.5;
                break;
            case kBtnStaduimTag:
                animationSpeed = 2.0;
                break;
            default:
                break;
        }
           
        [[NSNotificationCenter defaultCenter] postNotificationName:kSpeedSegementDidChange object:[NSNumber numberWithInteger:200-selected.tag]];


        UIButton* currentBtn = (UIButton*)[self viewWithTag:self.currentSelection];
        [currentBtn.layer removeAllAnimations];

        CABasicAnimation* spinAnimation = [CABasicAnimation
                                           animationWithKeyPath:@"transform.rotation"];
        spinAnimation.toValue = [NSNumber numberWithFloat:2*M_PI];
        spinAnimation.repeatCount = HUGE_VAL;
        spinAnimation.duration = animationSpeed;
        [selected.layer addAnimation:spinAnimation forKey:@"spinAnimation"];

        
        
        CAKeyframeAnimation* fadeInAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        fadeInAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1.0],
                              [NSNumber numberWithFloat:0.6],
                              [NSNumber numberWithFloat:1.0],nil];
        
        fadeInAnimation.duration = animationSpeed;
        fadeInAnimation.repeatCount = HUGE_VAL;
        [selected.layer addAnimation:fadeInAnimation forKey:@"fadeAnimation"];
        
        
        
        //i.e the first time this has been selected
        if(self.currentSelection==0){
            [UIView animateWithDuration:1.2 animations:^{
                lblStepTwo.alpha = 1;                   
            } completion:^(BOOL finished) {
            
                   [UIView animateWithDuration:1.2 delay:1.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                       lblStepThree.alpha = 1; 
                   }completion:nil];
              
            }];
        }
        
        self.currentSelection = selected.tag; 

    }
}




/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
