//
//  FaceDetectionViewController.m
//  MNNKitDemo
//
//  Created by tsia on 2019/12/24.
//  Copyright © 2019 tsia. All rights reserved.
//

#import "FaceDetectionViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <MNNFaceDetection/MNNFaceDetection.h>
#import <MNNFaceDetection/MNNFaceDetector.h>
#import "FaceDetectView.h"
#import "FaceDetectionImageViewController.h"

#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

@interface FaceDetectionViewController ()

@property (strong, nonatomic) UILabel *lbPointOrder;
@property (strong, nonatomic) UISwitch *pointOrder;
@property (strong, nonatomic) UILabel *lbCostTime;

@property (strong, nonatomic) MNNFaceDetector *faceDetector;


@end

@implementation FaceDetectionViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:@"人脸检测"];
    
    // 点序
    _lbPointOrder = [[UILabel alloc] initWithFrame:CGRectMake(10, self.navigationbarHeight+4, 40, 40)];
    _lbPointOrder.textColor = [UIColor greenColor];
    _lbPointOrder.text = @"点序";
    [self.view addSubview:_lbPointOrder];
    _pointOrder = [[UISwitch alloc] initWithFrame:CGRectMake(10+40, self.navigationbarHeight+8, 100, 40)];
    [self.view addSubview:_pointOrder];

    // 耗时ms
    _lbCostTime = [[UILabel alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(_lbPointOrder.frame)+8, 100, 40)];
    _lbCostTime.textColor = [UIColor greenColor];
    [self.view addSubview:_lbCostTime];
}


#pragma mark - mnn face
- (void)createKitInstance {
    if (self.faceDetector) {
        self.faceDetector = nil;
    }
    
    MNNFaceDetectorCreateConfig *createConfig = [[MNNFaceDetectorCreateConfig alloc] init];
    createConfig.detectMode = MNN_FACE_DETECT_MODE_VIDEO;
    [MNNFaceDetector createInstanceAsync:createConfig Callback:^(NSError *error, MNNFaceDetector *net) {
        
        self.faceDetector = net;
    }];
    
}

#pragma mark - action
- (void)onImageMode:(id)sender {
    [self.navigationController pushViewController:[FaceDetectionImageViewController new] animated:YES];
}

#pragma mark - ui
- (VideoBaseDetectView *)createDetectView {
    FaceDetectView *detectView = [[FaceDetectView alloc]init];
    return detectView;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer fromConnection:(nonnull AVCaptureConnection *)connection {
    if (!self.faceDetector) {
        return;
    }
    
    NSDictionary *angleDic = [self calculateInAndOutAngle];
    float inAngle = [angleDic[@"inAngle"] floatValue];
    float outAngle = [angleDic[@"outAngle"] floatValue];
    
    MNNFaceDetectConfig detectConfig = EYE_BLINK|MOUTH_AH|HEAD_YAW|HEAD_PITCH|BROW_JUMP;
    
    NSError *error = nil;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSArray<MNNFaceDetectionReport *> *detectResult = [self.faceDetector inference:CMSampleBufferGetImageBuffer(sampleBuffer) Config:detectConfig Angle:inAngle OutAngle:outAngle FlipType:FLIP_NONE error:&error];
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
        if ([self.detectView isKindOfClass:NSClassFromString(@"FaceDetectView")]) {
            FaceDetectView *faceDetectView = (FaceDetectView*)self.detectView;
            faceDetectView.showPointOrder = self->_pointOrder.isOn;
            faceDetectView.detectResult = detectResult;
        }
        
    });
    
}

@end
