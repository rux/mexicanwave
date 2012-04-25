//
//  CameraController.h
//  Loyalty
//
//  Created by Tom York on 25/07/2011.
//  Copyright 2011 Yell Group plc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

/// Needs CoreVideo, CoreMedia, AVFoundation.

// Forward declarations
@protocol CameraSessionFrameDelegate;

/**
 Provides a camera preview using AVFoundation functionality.
 The camera used is the default device. Currently this is the rear-facing camera on iPhone.
 AVFoundation should be weakly linked for some class messages to return correctly on targets lacking it.
 **/
@interface CameraSessionController : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
}
	
/**
 Observe this to be notified when the camera is adjusting focus, white balance or exposure settings.
 **/
@property (nonatomic, readonly, assign,getter=isAdjustingDeviceSettings) BOOL adjustingDeviceSettings; 

/**
 Delegate can receive uncompressed video frames. Only use if you need to process camera video.
 **/
@property (nonatomic, assign) IBOutlet id <CameraSessionFrameDelegate> outputDelegate;

/**
 Allows you to clip the output to specified rectangle before delivery through output delegate. 
 */
@property (nonatomic, assign) CGRect outputClipRect; 
    
/**
 NO if the camera is currently not available (e.g. disabled through restrictions, or
 required hardware is not attached to device.
 This property can be observed to detect when the camera becomes available.
 **/
@property (nonatomic, readonly, getter=isCameraViewAvailable) BOOL cameraViewAvailable;

/**
 YES if the camera system has a torch/flash function.
 **/
@property (nonatomic, readonly, getter=isTorchAvailable) BOOL torchAvailable;

/**
 YES if the camera should automatically attempt to focus on features in the scene. Default is NO.
 **/
@property (nonatomic, getter=isAutoFocusEnabled) BOOL autoFocusEnabled;

/**
 YES if the camera should automatically adjust its exposure settings in response 
 to the ambient light level (e.g. boost output in dark conditions).
 Default is YES.
 **/
@property (nonatomic, getter=isAutoExposureEnabled) BOOL autoExposureEnabled;

/** 
 YES if the camera should use the torch.
 **/
@property (nonatomic, assign, getter=isTorchEnabled) BOOL torchEnabled; 

/**
 When set, a video preview layer will be added as a sublayer.
 Clearing this property removes the preview layer.
 */
@property (nonatomic, retain) UIView* cameraView;	
    
/**
 This allows the user to get access to the last captured Image - from the still camera output
 */
@property (nonatomic, retain) UIImage* capturedImage;	

/**
 Returns NO if AVFoundation is unsupported on the target. 
 If you create a camera view on an unsupported target, it will initialise but will
 only fill its frame with the backgroundColor.
 **/
+ (BOOL)isSupported;	

/**
 Share this controller amongst all your camera displays, if you have more than one.
 */
+ (id)sharedCameraController;
		
/**
 Pauses camera video display.
 **/
- (void)pauseDisplay;

/**
 Starts or resumes camera video display.
 **/
- (void)resumeDisplay;

/** 
 Converts rectangle defined in the UIKit coordinate frame for the preview layer-containing view to the quartz
 coordinate frame suitable for contexts you create when acting as a CameraViewFrameDelegate.
 **/
- (CGRect)convertToVideoFrameCoordinates:(CGRect)rect;
/**
 Used to capture a photo - The completion handler allows you to respond to the image as 
 there can be delay from request to taken
 **/
   
-(void)capturePhotoWithCompletion:(void(^)(void))completion;

/**
 This returns if there is a photo that can be used
 **/
-(BOOL)isCapturedImage;
@end

/**
 Allows clients to receive video frames for their own processing.
 **/	
@protocol CameraSessionFrameDelegate <NSObject>
- (void)cameraController:(CameraSessionController*)cameraController didCaptureVideoFrame:(UIImage*)frameBuffer;
@end
