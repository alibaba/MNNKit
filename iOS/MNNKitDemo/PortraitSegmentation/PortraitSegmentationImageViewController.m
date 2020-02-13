//
//  PortraitSegmentationImageViewController.m
//  MNNKitDemo
//
//  Created by tsia on 2020/1/13.
//  Copyright © 2020 tsia. All rights reserved.
//

#import "PortraitSegmentationImageViewController.h"
#import <MNNPortraitSegmentation/MNNPortraitSegmentor.h>
#import <Accelerate/Accelerate.h>

#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

#define Mask_Width  216
#define Mask_Height  384

@interface PortraitSegmentationImageViewController ()

@property (strong, nonatomic) MNNPortraitSegmentor *portraitSegmentor;

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImage *image;

@property (strong, nonatomic) UILabel *lbTimeCost;

@end

@implementation PortraitSegmentationImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // init navi
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"开始分割" style:UIBarButtonItemStylePlain target:self action:@selector(onImageDetect:)]];
    
    // init ui
    self.imageView = [[UIImageView alloc]init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.imageView];
    
    self.image = [UIImage imageNamed:@"portrait_girl.jpg"];
    self.imageView.image = self.image;
    
    // scale to fit width
    CGFloat imgW = CGImageGetWidth(self.image.CGImage);
    CGFloat imgH = CGImageGetHeight(self.image.CGImage);
    CGFloat fixedHeight = ScreenWidth*imgH/imgW;
    self.imageView.frame = CGRectMake(0, self.navigationbarHeight, ScreenWidth, fixedHeight);
    
    _lbTimeCost = [[UILabel alloc] initWithFrame:CGRectMake(12, self.navigationbarHeight+8, 100, 30)];
    _lbTimeCost.textColor = [UIColor redColor];
    [self.view addSubview:_lbTimeCost];

    [MNNPortraitSegmentor createInstanceAsync:^(NSError *error, MNNPortraitSegmentor *portraitSegmentor) {
        self.portraitSegmentor = portraitSegmentor;
    }];
}

- (float)navigationbarHeight {
    return self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
}

#pragma mark - action
- (void)onImageDetect:(id)sender {
    
    NSError *error = nil;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSArray<NSNumber*> *detectResult = [self.portraitSegmentor inferenceWithImage:self.image angle:0 flipType:FLIP_NONE error:&error];
    NSTimeInterval timeElapsed = [[NSDate date] timeIntervalSince1970] - startTime;
    
    self.lbTimeCost.text = [NSString stringWithFormat:@"%.2fms", timeElapsed*1000];
    
    /**
     前景图像，rgba data
     */
    UIImage *fg_image = self.image;
    int w = fg_image.size.width;
    int h = fg_image.size.height;
    
    unsigned char *fg_rgba = (unsigned char *)calloc(w * h * 4, sizeof(unsigned char));
    {
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(fg_image.CGImage);
        CGContextRef contextRef = CGBitmapContextCreate(fg_rgba, w, h, 8, w * 4,
                                                        colorSpace,
                                                        kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);

        CGContextDrawImage(contextRef, CGRectMake(0, 0, w, h), fg_image.CGImage);
        CGContextRelease(contextRef);
        CGColorSpaceRelease(colorSpace);
    }
    
    float *detect_result = (float *)calloc(Mask_Width * Mask_Height, sizeof(float));
    for (int i=0; i<Mask_Width * Mask_Height; i++) {
        detect_result[i] = [detectResult[i] floatValue];
    }
    
    UIImage *resImage = [self mergedFgImage:fg_rgba Mask:detect_result];
    self.imageView.image = resImage;
    
    free(detect_result);
    free(fg_rgba);
}

// 前景、背景、mask，合成结果图片
- (UIImage *)mergedFgImage:(unsigned char*)fg_data Mask:(float*)mask {
    
    int w = self.image.size.width;
    int h = self.image.size.height;
    
    float *mask_scale = (float *)calloc(w * h * 4, sizeof(float));
    unsigned char *rgb_output = (unsigned char *)calloc(w * h * 4, sizeof(unsigned char));
    
    vImage_Buffer sourceBuffer = {
        .data = mask,
        .height = Mask_Height,
        .width = Mask_Width,
        .rowBytes = sizeof(float) * Mask_Width,
    };
    
    vImage_Buffer destinationBuffer = {
        .data = mask_scale,
        .height = h,
        .width = w,
        .rowBytes = sizeof(float) * w,
    };
    
    // scale
    vImageScale_PlanarF(&sourceBuffer, &destinationBuffer, NULL, kvImageNoFlags);
    
    int pixel_num = w * h;
    unsigned char *result_data = rgb_output;
    float *mask_data = mask_scale;
    
    for(int i = 0; i < pixel_num; i++){
        
        if(*mask_data > 0.5) {
            result_data[0] = fg_data[0];
            result_data[1] = fg_data[1];
            result_data[2] = fg_data[2];
        }else {
            result_data[0] = 255;
            result_data[1] = 255;
            result_data[2] = 255;
        }
        result_data[3] = 255;
        
        mask_data++;
        fg_data += 4;
        result_data += 4;
    }
    
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgb_output, w, h,
                                                 8, w * 4,
                                                 colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *resImage = [UIImage imageWithCGImage:cgImage];

    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    free(rgb_output);
    free(mask_scale);
    
    return resImage;
}

@end
