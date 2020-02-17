//
//  FaceDetectionImageViewController.m
//  MNNKitDemo
//
//  Created by tsia on 2020/1/13.
//  Copyright © 2020 tsia. All rights reserved.
//

#import "FaceDetectionImageViewController.h"
#import <MNNFaceDetection/MNNFaceDetection.h>
#import "FaceDetectView.h"

#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

@interface FaceDetectionImageViewController ()

@property (strong, nonatomic) MNNFaceDetector *faceDetector;

@property (strong, nonatomic) UIImage *image;

@property (strong, nonatomic) FaceDetectView *detectView;

@property (strong, nonatomic) UILabel *lbTimeCost;

@end

@implementation FaceDetectionImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // init navi
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"开始检测" style:UIBarButtonItemStylePlain target:self action:@selector(onImageDetect:)]];
    
    // init ui
    UIImageView *imageView = [[UIImageView alloc]init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
    
    self.image = [UIImage imageNamed:@"face_girl.JPG"];
    imageView.image = self.image;

    // scale to fit width
    CGFloat imgW = CGImageGetWidth(self.image.CGImage);
    CGFloat imgH = CGImageGetHeight(self.image.CGImage);
    CGFloat fixedHeight = ScreenWidth*imgH/imgW;
    imageView.frame = CGRectMake(0, self.navigationbarHeight, ScreenWidth, fixedHeight);
    
    self.detectView = [[FaceDetectView alloc] initWithFrame:imageView.frame];
    self.detectView.uiOffsetY = 0;
    self.detectView.useRedColor = YES;
    self.detectView.presetSize = CGSizeMake(imgW, imgH);
    [self.view addSubview:self.detectView];
    
    _lbTimeCost = [[UILabel alloc] initWithFrame:CGRectMake(12, self.navigationbarHeight+8, 100, 30)];
    _lbTimeCost.textColor = [UIColor redColor];
    [self.view addSubview:_lbTimeCost];
    
    // init face detector
    MNNFaceDetectorCreateConfig *createConfig = [[MNNFaceDetectorCreateConfig alloc] init];
    createConfig.detectMode = MNN_FACE_DETECT_MODE_IMAGE;
    [MNNFaceDetector createInstanceAsync:createConfig callback:^(NSError *error, MNNFaceDetector *faceDetector) {
        
        self.faceDetector = faceDetector;
    }];
    
}

- (float)navigationbarHeight {
    return self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
}

#pragma mark - action
- (void)onImageDetect:(id)sender {
    
    NSError *error = nil;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSArray<MNNFaceDetectionReport *> *reports = [self.faceDetector inferenceWithImage:self.image config:0 angle:0 outAngle:0 flipType:FLIP_NONE error:&error];
    NSTimeInterval timeElapsed = [[NSDate date] timeIntervalSince1970] - startTime;
    
    self.lbTimeCost.text = [NSString stringWithFormat:@"%.2fms", timeElapsed*1000];
    self.detectView.detectResult = reports;
}

@end
