//
//  SharePhotoViewController.h
//  MexicanWave
//
//  Created by Daniel Anderton on 16/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressView.h"

@interface SharePhotoViewController : UIViewController <UIAlertViewDelegate>
@property (retain, nonatomic) IBOutlet UIImageView *snapshotImageView;
@property (retain, nonatomic) UIImage* takenphoto;
@property (retain, nonatomic) IBOutlet ProgressView *progressView;
@end
