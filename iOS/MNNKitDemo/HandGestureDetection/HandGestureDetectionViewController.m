//
//  HandGestureDetectionViewController.m
//  MNNKitDemo
//
//  Created by tsia on 2019/12/25.
//  Copyright © 2019 tsia. All rights reserved.
//

#import "HandGestureDetectionViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <MNNHandGestureDetection/MNNHandGestureDetector.h>
#import "HandGestureDetectView.h"
#import "HandGestureDetectionImageViewController.h"

#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

@interface HandGestureDetectionViewController ()

@property (strong, nonatomic) UILabel *lbCostTime;

@property (strong, nonatomic) MNNHandGestureDetector *handGestureDetector;

@end

@implementation HandGestureDetectionViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 耗时ms
    _lbCostTime = [[UILabel alloc]initWithFrame:CGRectMake(10, 74, 100, 40)];
    _lbCostTime.textColor = [UIColor redColor];
    _lbCostTime.textColor = [UIColor greenColor];
    [self.view addSubview:_lbCostTime];
}

#pragma mark - mnn hand gesture
- (void)createKitInstance {
    if (self.handGestureDetector) {
        self.handGestureDetector = nil;
    }
    
    MNNHandGestureDetectorCreateConfig *config = [[MNNHandGestureDetectorCreateConfig alloc] init];
    config.detectMode = MNN_HAND_DETECT_MODE_VIDEO;
    [MNNHandGestureDetector createInstanceAsync:config callback:^(NSError *error, MNNHandGestureDetector *handgestureDetector) {
        
        self.handGestureDetector = handgestureDetector;
    }];
}

#pragma mark - ui
- (VideoBaseDetectView*)createDetectView {
    HandGestureDetectView *detectView = [[HandGestureDetectView alloc] init];
    return detectView;
}

#pragma mark - action
- (void)onImageMode:(id)sender {
    [self.navigationController pushViewController:[HandGestureDetectionImageViewController new] animated:YES];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer fromConnection:(nonnull AVCaptureConnection *)connection {
    if (!self.handGestureDetector) {
        return;
    }
    
    NSDictionary *angleDic = [self calculateInAndOutAngle];
    float inAngle = [angleDic[@"inAngle"] floatValue];
    float outAngle = [angleDic[@"outAngle"] floatValue];
    
    NSError *error = nil;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSArray<MNNHandGestureDetectionReport *> *detectResult = [self.handGestureDetector inferenceWithPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer) angle:inAngle outAngle:outAngle flipType:FLIP_NONE error:&error];
    NSTimeInterval timeElapsed = [[NSDate date] timeIntervalSince1970] - startTime;
    
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (detectResult!=nil && detectResult.count>0) {
            self->_lbCostTime.text = [NSString stringWithFormat:@"%.2fms", timeElapsed*1000];
        } else {
            self->_lbCostTime.text = @"0.00ms";
        }
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self.detectView isKindOfClass:NSClassFromString(@"HandGestureDetectView")]) {
            HandGestureDetectView *handDetectView = (HandGestureDetectView*)self.detectView;
            handDetectView.detectResult = detectResult;
        }
    });
    
}

@end
