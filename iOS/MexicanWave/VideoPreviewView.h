//
//  VideoPreviewView.h
//  Live Camera
//
//  Created by Daniel Anderton on 16/04/2012.
//  Copyright (c) 2012 Daniel Anderton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVFoundation/AVFoundation.h"

@interface VideoPreviewView : UIView

@property(nonatomic,getter = isVideoRunning) BOOL videoRunning;
@property(nonatomic,retain) UIImage* capturedImage;

-(void)startVideo;
-(void)stopVideo;
-(void)capturePhoto;
@end
