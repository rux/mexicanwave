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
@property (nonatomic) dispatch_queue_t caputureQueue; //< prevent main thread being blocked whilst starting and stoping the camera session

-(void)startVideo;
-(void)stopVideo;
-(void)capturePhotoWithCompletion:(void(^)(void))completion;
@end
