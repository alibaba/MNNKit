//
//  HandGestureDetectionImageViewController.m
//  MNNKitDemo
//
//  Created by tsia on 2020/1/13.
//  Copyright © 2020 tsia. All rights reserved.
//

#import "HandGestureDetectionImageViewController.h"
#import <MNNHandGestureDetection/MNNHandGestureDetection.h>
#import "HandGestureDetectView.h"

#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

@interface HandGestureDetectionImageViewController ()

@property (strong, nonatomic) MNNHandGestureDetector *handGestureDetector;

@property (strong, nonatomic) UIImage *image;

@property (strong, nonatomic) HandGestureDetectView *detectView;

@property (strong, nonatomic) UILabel *lbTimeCost;

@end

@implementation HandGestureDetectionImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // init navi
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"开始检测" style:UIBarButtonItemStylePlain target:self action:@selector(onImageDetect:)]];
    
    // init ui
    UIImageView *imageView = [[UIImageView alloc]init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [UIColor redColor];
    [self.view addSubview:imageView];
    
    self.image = [UIImage imageNamed:@"face_img.jpg"];
    imageView.image = self.image;
    
    // scale to fit width
    CGFloat imgW = CGImageGetWidth(self.image.CGImage);
    CGFloat imgH = CGImageGetHeight(self.image.CGImage);
    CGFloat fixedHeight = ScreenWidth*imgH/imgW;
    imageView.frame = CGRectMake(0, self.navigationbarHeight, ScreenWidth, fixedHeight);
    
    self.detectView = [[HandGestureDetectView alloc] initWithFrame:imageView.frame];
    self.detectView.uiOffsetY = 0;
    self.detectView.presetSize = CGSizeMake(imgW, imgH);
    [self.view addSubview:self.detectView];
    
    _lbTimeCost = [[UILabel alloc] initWithFrame:CGRectMake(12, self.navigationbarHeight+8, 100, 30)];
    _lbTimeCost.textColor = [UIColor whiteColor];
    [self.view addSubview:_lbTimeCost];
    
    // init hand gesture detector
    MNNHandGestureDetectorCreateConfig *config = [[MNNHandGestureDetectorCreateConfig alloc] init];
    config.detectMode = MNN_HAND_DETECT_MODE_IMAGE;
    [MNNHandGestureDetector createInstanceAsync:config callback:^(NSError *error, MNNHandGestureDetector *handgestureDetector) {
        
        self.handGestureDetector = handgestureDetector;
    }];
    
}

- (float)navigationbarHeight {
    return self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
}

#pragma mark - action
- (void)onImageDetect:(id)sender {
    
    NSError *error = nil;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSArray<MNNHandGestureDetectionReport *> *reports = [self.handGestureDetector inferenceWithImage:self.image angle:0 outAngle:0 flipType:FLIP_NONE error:&error];
    NSTimeInterval timeElapsed = [[NSDate date] timeIntervalSince1970] - startTime;
    
    self.lbTimeCost.text = [NSString stringWithFormat:@"%.2fms", timeElapsed*1000];
    self.detectView.detectResult = reports;
}

@end
