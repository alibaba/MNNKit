//
//  PortraitSegmentationViewController.m
//  MNNKitDemo
//
//  Created by tsia on 2019/12/26.
//  Copyright © 2019 tsia. All rights reserved.
//

#import "PortraitSegmentationViewController.h"
#import <MNNPortraitSegmentation/MNNPortraitSegmentor.h>
#import <Accelerate/Accelerate.h>
#import "PortraitSegmentationImageViewController.h"

#define Mask_Width  216
#define Mask_Height  384

@interface PortraitSegmentationViewController ()

@property (strong, nonatomic) UILabel *lbCostTime;

@property (nonatomic, strong) MNNPortraitSegmentor *portraitSegmentor;

@property (nonatomic, assign) float *detect_result;// 输出mask float数组
@property (nonatomic, assign) float *mask_scale;
@property (nonatomic, assign) unsigned char *rgb_output;

@property (nonatomic, assign) unsigned char *fg_rgba;// 前景
@property (nonatomic, assign) unsigned char *bg_rgba;// 背景

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign) int style;

@end

@implementation PortraitSegmentationViewController

-(void)dealloc {
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    if (_detect_result) free(_detect_result);
    if (_detect_result) free(_mask_scale);
    if (_detect_result) free(_rgb_output);
    
    if (_detect_result) free(_fg_rgba);
    if (_detect_result) free(_bg_rgba);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize currentPresetSize = [self sessionPresetToSize];
    
    self.detect_result = (float *)calloc(Mask_Width * Mask_Height, sizeof(float));
    self.mask_scale = (float *)calloc(currentPresetSize.width * currentPresetSize.height * 4, sizeof(float));
    self.rgb_output = (unsigned char *)calloc(currentPresetSize.width * currentPresetSize.height * 4, sizeof(unsigned char));
    
    self.fg_rgba = (unsigned char *)calloc(currentPresetSize.width * currentPresetSize.height * 4, sizeof(unsigned char));
    self.bg_rgba = (unsigned char *)calloc(currentPresetSize.width * currentPresetSize.height * 4, sizeof(unsigned char));
    
    
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"switch_camera"] style:UIBarButtonItemStylePlain target:self action:@selector(onSwitchCamera:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"image_mode"] style:UIBarButtonItemStylePlain target:self action:@selector(onImageMode:)], [[UIBarButtonItem alloc] initWithTitle:@"背景" style:UIBarButtonItemStylePlain target:self action:@selector(onSwitchStyle:)]];
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    [self.view addSubview:_imageView];
    
    // 耗时ms
    _lbCostTime = [[UILabel alloc]initWithFrame:CGRectMake(10, 74, 100, 40)];
    _lbCostTime.textColor = [UIColor redColor];
    _lbCostTime.textColor = [UIColor greenColor];
    [self.view addSubview:_lbCostTime];
}

-(BOOL)needCameraPreView {
    return NO;
}

- (void)createKitInstance {
    if (self.portraitSegmentor) {
        self.portraitSegmentor = nil;
    }
    
    [MNNPortraitSegmentor createInstanceAsync:^(NSError *error, MNNPortraitSegmentor *portraitSegmentor) {
        self.portraitSegmentor = portraitSegmentor;
    }];
}

//- (VideoBaseDetectView *)createDetectView {
//
//}

#pragma mark - action
- (void)onSwitchStyle:(id)sender {
    
    self.style++;
    self.style = self.style%4;
}

-(void)onImageMode:(id)sender {
    [self.navigationController pushViewController:[PortraitSegmentationImageViewController new] animated:YES];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer fromConnection:(nonnull AVCaptureConnection *)connection {
    if (!self.portraitSegmentor) {
        return;
    }

    NSDictionary *angleDic = [self calculateInAndOutAngle];
    float inAngle = [angleDic[@"inAngle"] floatValue];

    /**
     portrait inference
     */
    NSError *error = nil;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSArray<NSNumber*> *detectResult = [self.portraitSegmentor inferenceWithPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer) angle:inAngle flipType:FLIP_NONE error:&error];
    NSTimeInterval timeElapsed = [[NSDate date] timeIntervalSince1970] - startTime;

    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (detectResult!=nil && detectResult.count>0) {
//            self->_lbCostTime.text = [NSString stringWithFormat:@"%d fps", (int)(1/timeElapsed)];
            self->_lbCostTime.text = [NSString stringWithFormat:@"%.2f ms", timeElapsed*1000];
        } else {
            self->_lbCostTime.text = @"0.00ms";
        }
    });
    

    /**
     前景图像，rgba data
     */
    UIImage *fg_image = [self imageFromSampleBuffer:sampleBuffer orientation:UIImageOrientationUp];
    int w = fg_image.size.width;
    int h = fg_image.size.height;
    
    {
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(fg_image.CGImage);
        CGContextRef contextRef = CGBitmapContextCreate(self.fg_rgba, w, h, 8, w * 4,
                                                        colorSpace,
                                                        kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);

        CGContextDrawImage(contextRef, CGRectMake(0, 0, w, h), fg_image.CGImage);
        CGContextRelease(contextRef);
        CGColorSpaceRelease(colorSpace);
    }

    // 背景图像
    BOOL isWhiteBg = NO;
    {
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(fg_image.CGImage);
        CGContextRef contextRef = CGBitmapContextCreate(self.bg_rgba, w, h, 8, w * 4, colorSpace,
                                                        kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
        CGContextDrawImage(contextRef, CGRectMake(0, 0, w, h), fg_image.CGImage);
    
        if (_style==0) {// 图片背景
            
            UIImage *image_bg = [UIImage imageNamed:@"portrait_bg.jpg"];
            CGContextDrawImage(contextRef, CGRectMake(0, 0, w, h), image_bg.CGImage);
            
        } else if (_style==1) {// 动漫滤镜
            CGImageRef cgImage = CGBitmapContextCreateImage(contextRef);
            CIImage *beginImage = [[CIImage alloc] initWithCGImage:cgImage];
            CIContext *context = [CIContext contextWithOptions:nil];
            CIFilter *filter = [CIFilter filterWithName:@"CIComicEffect"];

            [filter setValue:beginImage forKey:kCIInputImageKey];
            CIImage *outputImage = [filter outputImage];

            CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
            UIImage *image_bg = [UIImage imageWithCGImage:cgimg];
            CGContextDrawImage(contextRef, CGRectMake(0, 0, w, h), image_bg.CGImage);
            CGImageRelease(cgimg);
            CGImageRelease(cgImage);
            
        } else if (_style==2) {// 宝石滤镜
            CGImageRef cgImage = CGBitmapContextCreateImage(contextRef);
            CIImage *beginImage = [[CIImage alloc] initWithCGImage:cgImage];
            CIContext *context = [CIContext contextWithOptions:nil];
            CIFilter *filter = [CIFilter filterWithName:@"CICrystallize"];
            [filter setDefaults];
            [filter setValue:beginImage forKey:kCIInputImageKey];
            CIImage *outputImage = [filter outputImage];
            outputImage = [outputImage imageByCroppingToRect:(CGRect){
                .origin.x = 0,
                .origin.y = 0,
                .size.width = outputImage.extent.size.width - 60,
                .size.height = outputImage.extent.size.height -60
            }];
            CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
            UIImage *image_bg = [UIImage imageWithCGImage:cgimg];
            CGContextDrawImage(contextRef, CGRectMake(0, 0, w, h), image_bg.CGImage);
            CGImageRelease(cgimg);
            CGImageRelease(cgImage);
        } else if (_style==3) {// 白色背景
            isWhiteBg = YES;
        }
        
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(contextRef);
    }
    
    for (int i=0; i<Mask_Width * Mask_Height; i++) {
        _detect_result[i] = [detectResult[i] floatValue];
    }
    
    UIImage *resImage = [self mergedFgImage:self.fg_rgba BgImage:isWhiteBg?nil:self.bg_rgba];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = resImage;
    });
    
}


- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer orientation:(UIImageOrientation)orientation{
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
    CIContext *context = [CIContext new];
    CGImageRef cgimage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *image= [UIImage imageWithCGImage:cgimage scale:1.f orientation:orientation];
    CGImageRelease(cgimage);
    return image;
}

// 前景、背景、mask，合成结果图片
- (UIImage *)mergedFgImage:(unsigned char*)fg_data BgImage:(unsigned char*)bg_data{
    
    CGSize currentPresetSize = [self sessionPresetToSize];
    
    vImage_Buffer sourceBuffer = {
        .data = self.detect_result,
        .height = Mask_Height,
        .width = Mask_Width,
        .rowBytes = sizeof(float) * Mask_Width,
    };
    
    vImage_Buffer destinationBuffer = {
        .data = self.mask_scale,
        .height = currentPresetSize.height,
        .width = currentPresetSize.width,
        .rowBytes = sizeof(float) * currentPresetSize.width,
    };
    
    // scale
    vImageScale_PlanarF(&sourceBuffer, &destinationBuffer, NULL, kvImageNoFlags);
    
    
    int pixel_num = currentPresetSize.width * currentPresetSize.height;
    unsigned char *result_data = self.rgb_output;
    float *mask_data = self.mask_scale;
    
    for(int i = 0; i < pixel_num; i++){
        
        if(*mask_data > 0.5) {
            result_data[0] = fg_data[0];
            result_data[1] = fg_data[1];
            result_data[2] = fg_data[2];
        }else {
            result_data[0] = bg_data!=nil?bg_data[0]:255;
            result_data[1] = bg_data!=nil?bg_data[1]:255;
            result_data[2] = bg_data!=nil?bg_data[2]:255;
        }
        result_data[3] = 255;
        
        mask_data++;
        fg_data += 4;
        if (bg_data!=nil) bg_data += 4;
        result_data += 4;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(self.rgb_output, currentPresetSize.width, currentPresetSize.height,
                                                 8, currentPresetSize.width * 4,
                                                 colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *resImage = [UIImage imageWithCGImage:cgImage];

    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    return resImage;
}

@end
