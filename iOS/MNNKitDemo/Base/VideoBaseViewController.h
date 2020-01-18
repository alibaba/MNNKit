//
//  VideoBaseViewController.h
//  MNNKitDemo
//
//  Created by tsia on 2019/12/26.
//  Copyright © 2019 tsia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import "VideoBaseDetectView.h"

#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

NS_ASSUME_NONNULL_BEGIN

@interface VideoBaseViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) VideoBaseDetectView *detectView;

- (float)navigationbarHeight;
- (NSDictionary*)calculateInAndOutAngle;
- (void)printAvailableVideoFormatTypes:(AVCaptureVideoDataOutput *)videoOutput;
- (CGSize)sessionPresetToSize;

/**
 override
 */
// optional
- (BOOL)needCameraPreView;
- (AVCaptureSessionPreset)cameraSessionPreset;

// required
- (void)createKitInstance;
- (VideoBaseDetectView*)createDetectView;

- (void)onImageMode:(id)sender;

@end

NS_ASSUME_NONNULL_END
