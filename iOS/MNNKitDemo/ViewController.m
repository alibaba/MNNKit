//
//  ViewController.m
//  MNNKitDemo
//
//  Created by tsia on 2019/12/24.
//  Copyright © 2019 tsia. All rights reserved.
//

#import "ViewController.h"
#import "FaceDetectionViewController.h"
#import "HandGestureDetectionViewController.h"
#import "PortraitSegmentationViewController.h"
#import <MNNKitCore/MNNMonitor.h>

#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    [self setTitle:@"MNNKit Demo"];
    
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    CGFloat naviBarHeight = self.navigationController.navigationBar.frame.size.height;
    
    UIButton *btnFace = [self createItemButton:@"人脸检测"];
    btnFace.frame = CGRectMake(12, statusBarHeight+naviBarHeight+20, ScreenWidth-12*2, 70);
    [self.view addSubview:btnFace];
    [btnFace addTarget:self action:@selector(onFaceDetection:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btnHand = [self createItemButton:@"手势识别"];
    btnHand.frame = CGRectMake(12, CGRectGetMaxY(btnFace.frame)+18, ScreenWidth-12*2, 70);
    [self.view addSubview:btnHand];
    [btnHand addTarget:self action:@selector(onHandGestureDetection:) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *btnPortrait = [self createItemButton:@"人像分割"];
    btnPortrait.frame = CGRectMake(12, CGRectGetMaxY(btnHand.frame)+18, ScreenWidth-12*2, 70);
    [self.view addSubview:btnPortrait];
    [btnPortrait addTarget:self action:@selector(onPortraitSegmentation:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [MNNMonitor setMonitorEnable:YES];
}

- (void)onFaceDetection:(id)sender {
    [self.navigationController pushViewController:[FaceDetectionViewController new] animated:YES];
}

- (void)onHandGestureDetection:(id)sender {
    [self.navigationController pushViewController:[HandGestureDetectionViewController new] animated:YES];
}

- (void)onPortraitSegmentation:(id)sender {
    [self.navigationController pushViewController:[PortraitSegmentationViewController new] animated:YES];
}

- (UIButton*)createItemButton:(NSString*)title {
    
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:20.f];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.layer.backgroundColor = [UIColor whiteColor].CGColor;
    button.layer.shadowOffset = CGSizeMake(1, 1);
    button.layer.shadowRadius = 2.0;
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOpacity = 0.2;
    button.layer.cornerRadius = 8.f;
    
    return button;
}

@end
