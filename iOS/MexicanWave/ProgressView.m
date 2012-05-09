//
//  ProgressView.m
//  MexicanWave
//
//  Created by Daniel Anderton on 09/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "ProgressView.h"
#import "QuartzCore/QuartzCore.h"
#define kDefaultAlpha 0.8f

@interface ProgressView ()
@property(nonatomic,retain) UILabel *titleLabel;
@property(nonatomic,retain) UIActivityIndicatorView* activityIndicator;
@property(nonatomic,retain) UIImageView* imageView;
@end

@implementation ProgressView
@synthesize titleLabel,activityIndicator,titleText;
@synthesize imageView,customImage;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitialisation];
        
    }
    return self;
}

-(void)commonInitialisation{
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 8.0f;
    self.backgroundColor = [UIColor blackColor];
    self.opaque = NO;
    self.alpha = 0.0;

    activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityIndicator startAnimating];
    activityIndicator.center = CGPointMake(self.frame.size.width*0.5, self.frame.size.height *0.3);
    [self addSubview:activityIndicator];
    
    
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width - 20, 50)];
    titleLabel.center = CGPointMake(self.frame.size.width*0.5, self.frame.size.height-35);
    titleLabel.numberOfLines = 2;
    titleLabel.font = [UIFont boldSystemFontOfSize:19];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.textAlignment = UITextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.shadowColor = [UIColor blackColor];
    titleLabel.shadowOffset = CGSizeMake(0, -1);
    titleLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:titleLabel];
        
    imageView = [[UIImageView alloc]initWithFrame:CGRectZero];
    imageView.alpha = 0;
    [self addSubview:imageView];
                
}

-(void)setTitleText:(NSString *)newText{
    
    //update the textlabel with the new text we have recieved
    if(newText != titleText){
        [titleText release];
        titleText = [newText retain];
        self.titleLabel.text = titleText;
    }
    
}

-(void)setCustomImage:(UIImage *)newImage{
    
    if(customImage!=newImage){
        [customImage release];
        customImage = [newImage retain];
        //Adjust the image view to the size of our new view
        self.imageView.image = customImage;
        self.imageView.frame = CGRectMake(0, 0, MIN(customImage.size.width,self.frame.size.width - 20), MIN(customImage.size.height,self.frame.size.height*0.5));
        imageView.center = CGPointMake(self.frame.size.width*0.5, self.frame.size.height *0.3);
    }
    
}

-(void)dealloc{
    [titleText release];
    [titleLabel release];
    [activityIndicator release];
    [imageView release];
    [customImage release];
    [super dealloc];
}


-(void)showWithAnimation:(BOOL)animate{
    if(animate){
        self.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = kDefaultAlpha; 
        }];
        
        return;
    }
    
    self.alpha = kDefaultAlpha;
}

-(void)hideWithAnimatiom:(BOOL)animate{
    
    if(animate){
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 0; 
        }];
        
        return;
    }    
    self.alpha = 0;
}

-(void)hideWithAnimatiom:(BOOL)animate withDelay:(NSTimeInterval)delay{
    
    double delayInSeconds = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self hideWithAnimatiom:animate];
    });
    
}

-(void)changeMode:(ProgressModes)mode{
    
    //Change the current HUD style - Progress spinner(Default) or image (Commonly used to show when completed).
    
    if(mode == kProgressModeSpin){
            self.activityIndicator.alpha = 1;
            self.imageView.alpha = 0;
    }
    else if(mode == kProgressModeImage){
            self.activityIndicator.alpha = 0;
            self.imageView.alpha = 1;
    }
    else{
        NSAssert(NO,@"Unrecongised HUD style %d",mode);
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
