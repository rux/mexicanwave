//
//  CameraController.m
//  Loyalty
//
//  Created by Tom York on 25/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CameraSessionController.h"
#import <ImageIO/CGImageProperties.h>

#define kSessionDispatchQueueName "com.yell.mexican.captureSessionQueue"
#define kDispatchQueueName "com.yell.mexican.frameQueue"
#define kDeliveryDispatchQueueName "com.yell.mexican.deliveryQueue"

@interface CameraSessionController ()
@property (nonatomic, retain) AVCaptureVideoPreviewLayer* videoLayer;	/// The layer responsible for displaying the camera output.
@property (nonatomic, retain) AVCaptureSession* captureSession;			/// The capture session.
@property (nonatomic, readwrite, assign, getter=isAdjustingDeviceSettings) BOOL adjustingDeviceSettings;
@property (nonatomic, readwrite, assign, getter=isCameraViewAvailable) BOOL cameraViewAvailable;
@property (nonatomic, assign) CGSize frameSize;		// Used to capture the output video size - only valid when sending frames to an output delegate.
@property (assign) BOOL shouldStart;	// Used to avoid a situation where rapid-fire calling of pause and resume cause substantial queues of session changes to form.
@property (assign) BOOL shouldAttach;	// Used to avoid a situation where rapid-fire calling of attach and detach causes substantial queues of delegate changes to form.

@property (retain) UIImage* frameBeingProcessed;
@property (nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput; //Used to capture still images whilst video is still playing.

@property (nonatomic) dispatch_queue_t queueForSessionControl;	// Used internally to avoid blocking the main thread when starting or stopping the capture session.
@property (nonatomic) dispatch_queue_t queueForFrameDelivery;     // Used to deliver frames to outputDelegate.

- (BOOL)configureCaptureChain;	/// If a device is available, tie it into the capture session if necessary and start the session running if possible.
- (void)configureDevicePreferences;	/// Set preferences including autofocus etc on active device.
- (void)deviceAvailabilityDidChange:(NSNotification*)notification; /// Called when device availability changes.
- (void)detachFrameDelegate;
- (void)attachFrameDelegate;
@end



@implementation CameraSessionController

#pragma mark -
#pragma mark Accessors

@synthesize cameraViewAvailable, autoFocusEnabled, autoExposureEnabled, adjustingDeviceSettings, torchEnabled;
@synthesize videoLayer, captureSession;
@synthesize outputDelegate, outputClipRect, frameSize, frameBeingProcessed;
@synthesize shouldStart, shouldAttach, cameraView,stillImageOutput;
@synthesize queueForSessionControl, queueForFrameDelivery;

- (void)setCameraView:(UIView *)newView {
	if(cameraView != newView) {
		[videoLayer removeFromSuperlayer];
		[cameraView release];
		cameraView = [newView retain];
		if(cameraView) {
			if(!videoLayer) {
				self.videoLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
				self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
       			}
          
            
            /**
                Modify the bounds of the layer and set the corner radius of the camera view to match the gap in middle of application.
            **/
			self.videoLayer.frame = cameraView.bounds;
			[cameraView.layer addSublayer:videoLayer];
            cameraView.clipsToBounds =YES;
            cameraView.layer.cornerRadius = 94.0f;

		}
	}
}

- (void)setCameraViewAvailable:(BOOL)isAvailable {
	if(isAvailable != cameraViewAvailable) {
		[self willChangeValueForKey:@"cameraViewAvailable"];
		cameraViewAvailable = isAvailable;
		[self didChangeValueForKey:@"cameraViewAvailable"];
	}
}

- (void)setAdjustingDeviceSettings:(BOOL)newSetting {
	if(adjustingDeviceSettings != newSetting) {
		[self willChangeValueForKey:@"adjustingDeviceSettings"];
		adjustingDeviceSettings = newSetting;
		[self didChangeValueForKey:@"adjustingDeviceSettings"];
	}
}

- (void)setAutoFocusEnabled:(BOOL)newValue {
	if(newValue != autoFocusEnabled) {
		[self willChangeValueForKey:@"autoFocusEnabled"];
		autoFocusEnabled = newValue;
		[self configureDevicePreferences];
		[self didChangeValueForKey:@"autoFocusEnabled"];
	}
}

- (void)setAutoExposureEnabled:(BOOL)newValue {
	if(newValue != autoExposureEnabled) {
		[self willChangeValueForKey:@"autoExposureEnabled"];
		autoExposureEnabled = newValue;
		[self configureDevicePreferences];
		[self didChangeValueForKey:@"autoExposureEnabled"];
	}
}

- (void)setTorchEnabled:(BOOL)newValue {
	if(!self.torchAvailable) {
		return;
	}
	
	if(newValue != torchEnabled) {
		[self willChangeValueForKey:@"torchEnabled"];
		torchEnabled = newValue;
		[self configureDevicePreferences];
		[self didChangeValueForKey:@"torchEnabled"];
	}
}

- (void)setOutputDelegate:(id <CameraSessionFrameDelegate>)newDelegate {
	if(newDelegate == outputDelegate) {
		return;
	}
    
    // Processing frames may take the delegate a long time, during which we need to communicate with it. Ensure access to it is mediated and that we retain it.
    @synchronized(self) {
        [outputDelegate release];
        outputDelegate = [newDelegate retain];
        self.frameSize = CGSizeZero;
        if(outputDelegate) {
            if(self.shouldAttach) {
                // We've already been asked to attach the output delegate.
                return;
            }
            
            // Record that we want to attach the delegate. 
            self.shouldAttach = YES;
            // Adding outputs can take a substantial amount of time, so we pass this task off to a dedicated queue asynchronously.
            dispatch_async(queueForSessionControl, ^{ if(self.shouldAttach) [self attachFrameDelegate]; });
        }
        else {
            if(!self.shouldAttach) {
                // We've already been asked to detach the output delegate.
                return;
            }
            
            // Record that we want to detach the delegate. 
            self.shouldAttach = NO;
            // Removing outputs can take a substantial amount of time, so we pass this task off to a dedicated queue asynchronously.
            dispatch_async(queueForSessionControl, ^{ if(!self.shouldAttach) [self detachFrameDelegate]; });
        }
    }
}

- (BOOL)isTorchAvailable {
	AVCaptureDevice* device = [[self.captureSession.inputs lastObject] device];
	if(!device) {
		return NO;
	}
	return [device isTorchModeSupported:AVCaptureTorchModeOn];
}

#pragma mark -
#pragma mark Public API

+ (BOOL)isSupported {
	// Currently returns NO on 3.x, YES on 4.x where AVFoundation should be supported and a camera is available.
	return NSClassFromString(@"AVCaptureVideoPreviewLayer") != nil;
}


- (void)pauseDisplay {
	if(!self.shouldStart) {
		// We've already been asked to stop the session.
		return;
	}
	// Record that we want to stop the session. 
	// The task blocks that we schedule will check this when they get executed on our session management queue.
	self.shouldStart = NO;
	// Dispatch a task to stop the session. If, when executed, the session has meanwhile been asked to start,
	// the task will do nothing.
	dispatch_async(queueForSessionControl, ^{ 
        if(!self.shouldStart) { 
            [self.captureSession stopRunning]; 
        } 
    });	
}

- (void)resumeDisplay {
	if(self.shouldStart) { 
		// We've already been asked to start the session.
		return;
	}
	// Record that we want to start the session. 
	// The task blocks that we schedule will check this when they get executed on our session management queue.
	self.shouldStart = YES;
	// Dispatch a task to start the session. If, when executed, the session has meanwhile been asked to stop,
	// the task will do nothing.
	dispatch_async(queueForSessionControl, ^{ 
        if(self.shouldStart) { 
            // Try and start capture running.
            if(!cameraViewAvailable) {
                cameraViewAvailable = [self configureCaptureChain];        
            }
            if(cameraViewAvailable) {
                [self.captureSession startRunning]; 
            }
        } 
    });
}

- (CGRect)convertToVideoFrameCoordinates:(CGRect)rect {
	if(!self.cameraView || self.cameraView.bounds.size.width == 0.0f) {
		return CGRectZero;
	}
	
	// Camera video undergoes the following transformations into the preview layer:
	// 1. Rotated CW by a quarter-turn (frame is read out horizontally from the camera)
	// 2. Coordinate system conventions flipped from Quartz to UIKit
	// 3. Scaled to fill the preview layer's bounds using aspect fill, i.e. scaled by largest ratio between layer and video dimensions
	// 4. Translated to center the result
	const CGFloat scaleFactor = self.frameSize.height / self.cameraView.bounds.size.width;
	const CGFloat offsetTerm = 0.5f*(self.frameSize.width - scaleFactor*self.cameraView.bounds.size.height);
	const CGAffineTransform tx = CGAffineTransformMake(0.0f, scaleFactor, scaleFactor, 0, offsetTerm, 0);
	return CGRectApplyAffineTransform(rect, tx);
}


#pragma mark - Lifecycle

+ (id)sharedCameraController {
	static dispatch_once_t token;
	static id instance = nil;	
	dispatch_once(&token, ^{ instance = [[self alloc] init]; });
	return instance;		
}

- (id)init {
	if(!(self = [super init])) {
		return nil;
	}
	
	if(![[self class] isSupported]) {
		// Nothing else to be done.
		[self release], self = nil;
		return nil;
	}
       
	// Common ivars
	// Setup default device preferences.
	autoFocusEnabled = YES;
	autoExposureEnabled = YES;	
	
	queueForSessionControl = dispatch_queue_create(kSessionDispatchQueueName, NULL);
    queueForFrameDelivery = dispatch_queue_create(kDeliveryDispatchQueueName, NULL);	

	// Even if a device isn't currently connected the AVFoundation
	// is supported on this platform.	
	// Create a capture session.
	captureSession = [[AVCaptureSession alloc] init];
		
	// We're interested to know if device availability changes.
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter addObserver:self selector:@selector(deviceAvailabilityDidChange:) name:AVCaptureDeviceWasConnectedNotification object:nil];
	[notifyCenter addObserver:self selector:@selector(deviceAvailabilityDidChange:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
	return self;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[videoLayer release]; 
	[cameraView release];
    [stillImageOutput release];
	
	AVCaptureDevice* device = [[self.captureSession.inputs lastObject] device];
	[device removeObserver:self forKeyPath:@"adjustingFocus"];
	[device removeObserver:self forKeyPath:@"adjustingExposure"];
	[device removeObserver:self forKeyPath:@"adjustingWhiteBalance"];
	
    [frameBeingProcessed release];
	[captureSession release];
    dispatch_release(queueForFrameDelivery);
	dispatch_release(queueForSessionControl);
    [super dealloc];
}

#pragma mark -
#pragma mark Private API


- (BOOL)configureCaptureChain {
	// If the session is running we assume there's nothing to be done.
	if([self.captureSession isRunning] && [self.captureSession.inputs count] > 0) {
		// Camera is available and running.
		// TODO: settings...
		return YES;
	}
	
	// Maybe a session input is already set and we can just start the session running again?
	if([[self.captureSession inputs] count] > 0) {
		// The session has an input, it may just need to be started running again.
		for(AVCaptureDeviceInput* oneInput in [self.captureSession inputs]) {
			if([oneInput.device isConnected]) {
				// This device is linked to the session and is available; we can just
				// start the session running.
				[self.captureSession startRunning];
				break;
			}
		}
		return [self.captureSession isRunning];
	}
	
	// The session hasn't got any inputs, so configure one.
	// Select the default device for video.
	AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];	
	if(!device) {
		return NO;
	}
	
	// There is a default device available. Choose a quality preset.
	NSString* qualityPreset = nil;
	if([self.captureSession canSetSessionPreset:AVCaptureSessionPresetMedium] && [device supportsAVCaptureSessionPreset:AVCaptureSessionPresetMedium]) {
		// Configure the session at medium quality.
		qualityPreset = AVCaptureSessionPresetMedium;
	}
	else if([self.captureSession canSetSessionPreset:AVCaptureSessionPresetLow] && [device supportsAVCaptureSessionPreset:AVCaptureSessionPresetLow]) {
		// Fall back to low quality
		qualityPreset = AVCaptureSessionPresetLow;
	}
	
	if(!qualityPreset) {
		return NO;
	}	
	
	// We were able to select a suitable quality.
	self.captureSession.sessionPreset = qualityPreset;
	
	// Now create an input using the device.					
	AVCaptureDeviceInput* input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil]; 
	if(!input) {
		// Was not able to create input for the device 
		return NO;		
	}
	
	if(![self.captureSession canAddInput:input]) {
		[input release];
		return NO;
	}
	
    //set up for still image output
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	NSDictionary *outputSettings = [NSDictionary dictionaryWithObject:AVVideoCodecJPEG forKey:AVVideoCodecKey];
	[stillImageOutput setOutputSettings:outputSettings];
	[self.captureSession addOutput:stillImageOutput];

    
	// We can add an input (AVFoundation currently only supports one)
	[self.captureSession addInput:input];
	[input release];
	
	// Configure the devices options, e.g. autofocus.
	[self configureDevicePreferences];
	
	// Observe focus changes
	[device addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:NULL];
	[device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:NULL];
	[device addObserver:self forKeyPath:@"adjustingWhiteBalance" options:NSKeyValueObservingOptionNew context:NULL];
	
	return YES;
}

- (void)configureDevicePreferences {
	AVCaptureDevice* device = [[self.captureSession.inputs lastObject] device];
	if(![device lockForConfiguration:nil]) {
		return;
	}
	
	const AVCaptureFocusMode desiredFocusMode = self.autoFocusEnabled ? AVCaptureFocusModeContinuousAutoFocus : AVCaptureFocusModeLocked;
	if([device isFocusModeSupported:desiredFocusMode]) {
		device.focusMode = desiredFocusMode;
	}
	
	const AVCaptureExposureMode desiredExpoMode = self.autoExposureEnabled ? AVCaptureExposureModeAutoExpose : AVCaptureExposureModeLocked;
	if([device isExposureModeSupported:desiredExpoMode]) {
		device.exposureMode = desiredExpoMode;
	}
	
	const AVCaptureTorchMode desiredTorchMode = self.torchEnabled ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;	
	if([device isTorchModeSupported:desiredTorchMode]) {
		device.torchMode = desiredTorchMode;
	}
	
	[device unlockForConfiguration];
}

#pragma mark -
#pragma mark Add and remove frame observer

- (void)detachFrameDelegate {
	// No delegate any more, remove video capture output.
	if([[self.captureSession outputs] count]) {
		[self.captureSession removeOutput:[[self.captureSession outputs] lastObject]];
	}	
}

- (void)attachFrameDelegate {
	// Delegate created, attach us if necessary.
	if([[self.captureSession outputs] count]) {
		return;
	}
	
	AVCaptureVideoDataOutput* captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	NSDictionary* settings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]; 
	[captureOutput setVideoSettings:settings]; 
	captureOutput.alwaysDiscardsLateVideoFrames = YES;
	
	dispatch_queue_t queueForFrames = dispatch_queue_create(kDispatchQueueName, NULL);	
	///captureOutput.minFrameDuration = CMTimeMake(1, 10);
	[captureOutput setSampleBufferDelegate:self queue:queueForFrames];		
	dispatch_release(queueForFrames);
	[self.captureSession addOutput:captureOutput];
	[captureOutput release];	
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(self.frameBeingProcessed) {
        // We're already busy
        return;
    }
    
	if(CGSizeEqualToSize(self.frameSize, CGSizeZero)) {
		CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
		const size_t width = CVPixelBufferGetWidth(imageBuffer); 
		const size_t height = CVPixelBufferGetHeight(imageBuffer); 		
		self.frameSize = CGSizeMake(width, height);
	}
    
    if(CGRectEqualToRect(self.outputClipRect, CGRectZero)) {
		// Nil frame.
		return;
	}
    
	if(!CMSampleBufferDataIsReady(sampleBuffer)) {
		// Data is not ready
		return;
	}
	
	// Lock the image and create a context on it.
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
	if(CVPixelBufferLockBaseAddress(imageBuffer,0) != kCVReturnSuccess) {
		return;
	}
	const size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
	const size_t width = CVPixelBufferGetWidth(imageBuffer); 
	const size_t height = CVPixelBufferGetHeight(imageBuffer); 
	uint8_t* imageBytes = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer); 	
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
	CGContextRef imageContext = CGBitmapContextCreate(imageBytes, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst); 
	CGColorSpaceRelease(colorSpace);
	
	if(!imageContext) {
		CVPixelBufferUnlockBaseAddress(imageBuffer,0);	
		return;
	}
	
	CGImageRef image = CGBitmapContextCreateImage(imageContext); 
	CGContextRelease(imageContext); 
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
	if(!image) {
		return;
	}
	
	// Find the section of the video frame corresponding to the scan overlay indicator that shows the user where to frame the QR code.
	// Get the frame clip rectangle 
	CGRect activeRect = [self convertToVideoFrameCoordinates:self.outputClipRect];
	CGImageRef croppedImage = CGImageCreateWithImageInRect(image, activeRect);
	CGImageRelease(image);
	self.frameBeingProcessed = [[[UIImage alloc] initWithCGImage:croppedImage] autorelease];
	CGImageRelease(croppedImage);
    
    // Processing frames may take the delegate a long time; use a queue to do the work.
    id frameTarget = self.outputDelegate;
    dispatch_async(queueForFrameDelivery, ^{     
        [frameTarget cameraController:self didCaptureVideoFrame:self.frameBeingProcessed]; 
        // Ready for another image to be processed.
        self.frameBeingProcessed = nil; 
    });
}

#pragma mark - Notifications for device/session

- (void)deviceAvailabilityDidChange:(NSNotification*)notification {
	if([notification.name isEqualToString:AVCaptureDeviceWasConnectedNotification] || [notification.name isEqualToString:AVCaptureDeviceWasDisconnectedNotification]) {
        NSLog(@"%@", notification.name);
        dispatch_async(self.queueForSessionControl, ^{
            self.cameraViewAvailable = [self configureCaptureChain];            
        });
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	AVCaptureDevice* device = [[self.captureSession.inputs lastObject] device];
	if(!device) {
		self.adjustingDeviceSettings = NO;
		return;
	}
	
	self.adjustingDeviceSettings = device.adjustingFocus || device.adjustingWhiteBalance || device.adjustingExposure;
}

-(void)capturePhotoWithCompletion:(StillPhotoCallBack)completion{
    //double check the video is started
    [self resumeDisplay];
    
    AVCaptureConnection *videoConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];

	[stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
		 CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
		 // Do something with the attachments. 
         DLog(@"attachements: %@", exifAttachments);	
         
         if(error){
             completion(nil,error);
             return;
         }
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         //we have a new image so clear out the old and set the new image.
         UIImage *capturedImage = [[UIImage alloc] initWithData:imageData];
         if(completion){
             completion(capturedImage,nil);
         }
         [capturedImage release];
	 }];    
}

@end
