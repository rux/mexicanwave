//
//  VideoPreviewView.m
//  Live Camera
//
//  Created by Daniel Anderton on 16/04/2012.
//  Copyright (c) 2012 Daniel Anderton. All rights reserved.
//

#import "VideoPreviewView.h"
#import <ImageIO/CGImageProperties.h>
@interface VideoPreviewView()

@property(nonatomic,retain) AVCaptureSession *session;
@property(nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput;

-(void)commonInitialisation;

@end

@implementation VideoPreviewView
@synthesize session,videoRunning,stillImageOutput,capturedImage,caputureQueue;

-(void)dealloc{
    dispatch_release(caputureQueue);
    [capturedImage release];
    [stillImageOutput release];
    [session release];
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
    caputureQueue =  dispatch_queue_create("com.yell.mexican.capture", NULL);

    
    //create a session which can be accessed throughout.
	session = [[AVCaptureSession alloc] init];
	session.sessionPreset = AVCaptureSessionPresetMedium;
    
    //create the creview layer and attach it to self (as we inheirt from UIVIEW)
    //set the frame to match ours - and ratio appropriately 
	AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	captureVideoPreviewLayer.frame = self.frame;

	[self.layer addSublayer:captureVideoPreviewLayer];
    
    //get the default device and set it as the device input.
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
	NSError *error = nil;
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	if (!input) {
		// Handle the error appropriately.
		NSLog(@"ERROR: trying to open camera: %@", error);
	}
	[session addInput:input];
    
    
    //set up still photo capture - (For Future)
    // We retain a handle to the still image output and use this when we capture an image.
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
	[stillImageOutput setOutputSettings:outputSettings];
	[session addOutput:stillImageOutput];
    //make sure its not runnin
    self.videoRunning = NO;

}

-(void)startVideo{
    //check if video is allready running - if not start the camera session
    if(self.isVideoRunning){
        return;
    }
    dispatch_async(caputureQueue, ^{
        if(!self.isVideoRunning){
            [session startRunning];
            self.videoRunning = YES;
        }

    });

}

-(void)stopVideo{
    //check if video is allready stoped - if not start the camera session
    if(!self.isVideoRunning){
        return;
    }
    dispatch_async(caputureQueue, ^{
        if(self.isVideoRunning){
            [session stopRunning];
            self.videoRunning = NO;
        }
        
    });

}



-(void)capturePhotoWithCompletion:(void(^)(void))completion{
    //double check the video is started
    [self startVideo];
    
    AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in stillImageOutput.connections)
	{
		for (AVCaptureInputPort *port in [connection inputPorts])
		{
			if ([[port mediaType] isEqual:AVMediaTypeVideo] )
			{
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) { break; }
	}
    


	[stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
		 CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
		 // Do something with the attachments. 
         NSLog(@"attachements: %@", exifAttachments);
		 
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         //we have a new image so clear out the old and set the new image.
         self.capturedImage = nil;
         capturedImage = [[UIImage alloc] initWithData:imageData];
         if(completion){
             completion();
         }
         
	 }];

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
