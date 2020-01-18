//
//  VideoBaseViewController.m
//  MNNKitDemo
//
//  Created by tsia on 2019/12/26.
//  Copyright © 2019 tsia. All rights reserved.
//

#import "VideoBaseViewController.h"

@interface VideoBaseViewController ()

@property (nonatomic, strong) CMMotionManager *motionManager;// 设备传感器

@property (nonatomic, assign) int deviecAutoRotateAngle;// 开启系统自动旋转时，设备旋转的角度0/90/270（手机倒置180不会更新）

@property (strong, nonatomic) AVCaptureDeviceInput *captureInput;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (assign, nonatomic) BOOL isFrontCamera;

@property (nonatomic, copy) AVCaptureSessionPreset sessionPreset;// 摄像头输出分辨率

@end

@implementation VideoBaseViewController

#pragma mark - life cycle
-(void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 设备方向变化监听（需开启系统自动旋转功能，关闭时方向永远是UIDeviceOrientationPortrait）
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    // pull获取设备陀螺仪数据（和系统自动旋转是否打开无关）
    self.motionManager = [[CMMotionManager alloc] init];
    if ([self.motionManager isDeviceMotionAvailable]) {
        [self.motionManager startDeviceMotionUpdates];
    }
    
    _deviecAutoRotateAngle = [self currentAngle];
    _isFrontCamera = YES;
    _sessionPreset = [self cameraSessionPreset];// or others ...
    
    [self initSession];
    [self initCameraPreview];
    
    [self updateVideoOutputConfig];
    [self updatePreviewlayer];
    
    /**
     init hand gesture detect
     */
    [self createKitInstance];
    
    // init ui
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"switch_camera"] style:UIBarButtonItemStylePlain target:self action:@selector(onSwitchCamera:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"image_mode"] style:UIBarButtonItemStylePlain target:self action:@selector(onImageMode:)]];
    
    
    // init detect view
    self.detectView = [self createDetectView];
    self.detectView.uiOffsetY = self.navigationbarHeight;
    self.detectView.presetSize = [self sessionPresetToSize];
    [self.view addSubview:self.detectView];
    
    [self updateLayoutWithOrientationOrPresetChanged];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    
    if (self.captureSession) {
        [self.captureSession startRunning];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:YES];
    
    if (self.captureSession) {
        [self.captureSession stopRunning];
    }
}

#pragma mark - mnn kit instance
- (void)createKitInstance {
    // override
}

- (VideoBaseDetectView*)createDetectView {
    // override
    return nil;
}

#pragma mark - camera
- (BOOL)needCameraPreView {
    // override
    return YES;
}

-(AVCaptureSessionPreset)cameraSessionPreset {
    // override
    return AVCaptureSessionPreset1280x720;// default
}

- (void)initCameraPreview {
    if ([self needCameraPreView]) {
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        [self.previewLayer setVideoGravity:AVLayerVideoGravityResize];// TODO
        [self.view.layer addSublayer:self.previewLayer];
    }
}

- (void)initSession {

    _captureInput = [[AVCaptureDeviceInput alloc]initWithDevice:[self cameraWithPosition:_isFrontCamera] error:nil];

    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
    /**
     print available video output format：[self availableVideoFormatTypes:captureOutput];
     一般只支持这几种格式：
     kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange（yuv420sp nv12）
     kCVPixelFormatType_420YpCbCr8BiPlanarFullRange（yuv420sp nv12）
     kCVPixelFormatType_32BGRA
     */
    captureOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
                             };
    [captureOutput setSampleBufferDelegate:self queue:queue];

    self.captureSession = [[AVCaptureSession alloc] init];
    if ([self.captureSession canAddInput:_captureInput]) {
        [self.captureSession addInput:_captureInput];
    }
    if ([self.captureSession canAddOutput:captureOutput]) {
        [self.captureSession addOutput:captureOutput];
    }

    self.captureSession.sessionPreset = _sessionPreset;// 分辨率
}

- (AVCaptureDevice *)cameraWithPosition:(BOOL)isFrontCamera {
    AVCaptureDevicePosition devicePosition = isFrontCamera?AVCaptureDevicePositionFront:AVCaptureDevicePositionBack;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices ) {
        if (device.position == devicePosition) {
            return device;
        }
    }
    return nil;
}

// 设置output方向+镜像，保证能正常预览
- (void)updatePreviewlayer {
    if (!self.previewLayer || ![self needCameraPreView]) {
        return;
    }

    AVCaptureConnection *connection = self.previewLayer.connection;
    if (connection.supportsVideoOrientation) connection.videoOrientation = [self orientationAngleToCaptureVideoOrientation];
    if (connection.supportsVideoMirroring && !connection.automaticallyAdjustsVideoMirroring) connection.videoMirrored = _isFrontCamera;
}

// 设置output方向+镜像，保证输出和当前屏幕显示的一致
- (void)updateVideoOutputConfig {
    AVCaptureVideoDataOutput *output = self.captureSession.outputs.firstObject;
    if (0==output.connections.count) {
        return;
    }
    AVCaptureConnection *connection = output.connections[0];

    if (connection.supportsVideoOrientation) connection.videoOrientation = [self orientationAngleToCaptureVideoOrientation];
    if (connection.supportsVideoMirroring && !connection.automaticallyAdjustsVideoMirroring) connection.videoMirrored = _isFrontCamera;
}

- (AVCaptureVideoOrientation)orientationAngleToCaptureVideoOrientation {
    switch (_deviecAutoRotateAngle) {
            case 0:
            return AVCaptureVideoOrientationPortrait;
            break;
            case 90:
            return AVCaptureVideoOrientationLandscapeLeft;
            break;
            /**
             手机倒置时，标题栏并不会翻转，仍然保持上个状态
             */
//            case 180:
//            return AVCaptureVideoOrientationPortraitUpsideDown;
//            break;
            case 270:
            return AVCaptureVideoOrientationLandscapeRight;
            break;

        default:
            break;
    }

    return AVCaptureVideoOrientationPortrait;
}

#pragma mark - ui
- (void)updateLayoutWithOrientationOrPresetChanged {
    
    CGSize presetSize = [self sessionPresetToSize];
    
    if (ScreenWidth<ScreenHeight) {
        CGFloat adjustHeight = ScreenWidth*presetSize.height/presetSize.width;// 适应宽
        
        // 屏幕翻转后，坐标系从标题栏左上角开始计算，屏幕宽高也会变化
        if ([self needCameraPreView]) {
            self.previewLayer.frame = CGRectMake(0, 0, ScreenWidth, adjustHeight);
        }
        self.detectView.frame = CGRectMake(0, 0, ScreenWidth, adjustHeight);
    } else {
        CGFloat adjustWidth = ScreenHeight*presetSize.height/presetSize.width;// 适应宽
        
        if ([self needCameraPreView]) {
            self.previewLayer.frame = CGRectMake(0, 0, adjustWidth, ScreenHeight);
        }
        self.detectView.frame = CGRectMake(0, 0, adjustWidth, ScreenHeight);
    }
    
}

- (CGSize)sessionPresetToSize {
    
    if ([_sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        return CGSizeMake(1080, 1920);
    } else if ([_sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        return CGSizeMake(720, 1280);
    } else if ([_sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
        return CGSizeMake(480, 640);
    }
    
    return CGSizeZero;
}

//导航栏高度+状态栏高度
- (float)navigationbarHeight {
    return self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
}

#pragma mark - action
- (void)onSwitchCamera:(id)sender  {
    
    NSArray *inputs = self.captureSession.inputs;
    for (AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevice *newCamera =nil;
            AVCaptureDeviceInput *newInput =nil;
            
            newCamera = [self cameraWithPosition:!_isFrontCamera];
            _isFrontCamera = !_isFrontCamera;
            
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            // beginConfiguration ensures that pending changes are not applied immediately
            [self.captureSession beginConfiguration];
            
            [self.captureSession removeInput:input];
            [self.captureSession addInput:newInput];
            
            // Changes take effect once the outermost commitConfiguration is invoked.
            [self.captureSession commitConfiguration];
            break;
        }
    }
    
    [self updateVideoOutputConfig];
}

- (void)onImageMode:(id)sender {
    // stub
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
//- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer fromConnection:(nonnull AVCaptureConnection *)connection {
//}

- (NSDictionary*)calculateInAndOutAngle {
    
    double degree = [self rotateDegreeFromDeviceMotion];
    //可以根据不同角度检测处理，这里只检测四个角度的改变
    int rotateDegree = (((int)degree + 45) / 90 * 90) % 360;// 0/90/180/270

    //    NSLog(@"物理设备旋转角度: %d", rotateDegree);
    //    NSLog(@"自动旋转j角度: %d", _deviecAutoRotateAngle);
        
    /**
    如果自动旋转角度为0，无论有没有打开自动旋转，都当做关闭自动旋转处理
    如果自动旋转角度不为0，则一定是打开的自动旋转
    */
    int inAngle = 0;
    int outAngle = 0;
    if (self.deviecAutoRotateAngle==0) {
        inAngle = rotateDegree;
        outAngle = rotateDegree;
    }
    /**
    自动旋转打开时，手机旋转180标题栏不会翻转，保留上一个的状态
    */
    else if (rotateDegree==180) {
            
        if (self.deviecAutoRotateAngle==90) {
            inAngle = 90;
            outAngle = 90;
        }else if (_deviecAutoRotateAngle==270) {
            inAngle = 270;
            outAngle = 270;
        }
            
    } else {
        inAngle = 0;
        outAngle = 0;
    }
    
    return @{@"inAngle":@(inAngle), @"outAngle":@(outAngle)};
}

// 根据陀螺仪数据计算的设备旋转角度（和系统自动旋转是否打开无关）
- (double)rotateDegreeFromDeviceMotion {
    
    double gravityX = self.motionManager .deviceMotion.gravity.x;
    double gravityY = self.motionManager .deviceMotion.gravity.y;
    //double gravityZ = self.motionManager .deviceMotion.gravity.z;
    // 手机顺时针旋转的角度 0-360
    double xyTheta = atan2(gravityX, -gravityY) / M_PI * 180.0;
    if (gravityX<0) {
        xyTheta = 360+xyTheta;
    }
    
    return xyTheta;
}
    
#pragma mark - notification
- (BOOL)onDeviceOrientationDidChange:(NSNotification*)notification {
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    //识别当前设备的旋转方向
    switch (orientation) {
            case UIDeviceOrientationFaceUp:
            NSLog(@"屏幕幕朝上平躺");
            break;
            
            case UIDeviceOrientationFaceDown:
            NSLog(@"屏幕朝下平躺");
            break;
            
            case UIDeviceOrientationUnknown://系统当前无法识别设备朝向，可能是倾斜
            NSLog(@"未知方向");
            break;
            
            case UIDeviceOrientationLandscapeLeft:// 270
        {
            self.deviecAutoRotateAngle = 270;
            NSLog(@"屏幕向左橫置");
        }
            break;
            
            case UIDeviceOrientationLandscapeRight:// 90
        {
            self.deviecAutoRotateAngle = 90;
            NSLog(@"屏幕向右橫置");
        }
            break;
            
            case UIDeviceOrientationPortrait:// 0
        {
            self.deviecAutoRotateAngle = 0;
            NSLog(@"屏幕直立");
        }
            break;
            
            /**
             手机倒置时，标题栏并不会翻转，保持上一个状态。标题栏有翻转才会触发预览和输出的更新。
             */
            case UIDeviceOrientationPortraitUpsideDown:// 180
        {
//            self.deviecAutoRotateAngle = 180;
            NSLog(@"屏幕直立，上下顛倒");
            return YES;
        }
            break;
    
        default:
            NSLog(@"无法识别");
            break;
    }
    
    [self updateVideoOutputConfig];
    [self updatePreviewlayer];
    
    [self updateLayoutWithOrientationOrPresetChanged];

    return YES;
}

- (int)currentAngle {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            return 0;
        case UIDeviceOrientationPortraitUpsideDown:
            return 180;
        case UIDeviceOrientationLandscapeLeft:
            return 270;
        case UIDeviceOrientationLandscapeRight:
            return 90;
            
        default:
            return 0;
            break;
    }
}

#pragma mark - utils
- (void)printAvailableVideoFormatTypes:(AVCaptureVideoDataOutput *)videoOutput {

    NSDictionary *formats = [NSDictionary dictionaryWithObjectsAndKeys:
           @"kCVPixelFormatType_1Monochrome", [NSNumber numberWithInt:kCVPixelFormatType_1Monochrome],
           @"kCVPixelFormatType_2Indexed", [NSNumber numberWithInt:kCVPixelFormatType_2Indexed],
           @"kCVPixelFormatType_4Indexed", [NSNumber numberWithInt:kCVPixelFormatType_4Indexed],
           @"kCVPixelFormatType_8Indexed", [NSNumber numberWithInt:kCVPixelFormatType_8Indexed],
           @"kCVPixelFormatType_1IndexedGray_WhiteIsZero", [NSNumber numberWithInt:kCVPixelFormatType_1IndexedGray_WhiteIsZero],
           @"kCVPixelFormatType_2IndexedGray_WhiteIsZero", [NSNumber numberWithInt:kCVPixelFormatType_2IndexedGray_WhiteIsZero],
           @"kCVPixelFormatType_4IndexedGray_WhiteIsZero", [NSNumber numberWithInt:kCVPixelFormatType_4IndexedGray_WhiteIsZero],
           @"kCVPixelFormatType_8IndexedGray_WhiteIsZero", [NSNumber numberWithInt:kCVPixelFormatType_8IndexedGray_WhiteIsZero],
           @"kCVPixelFormatType_16BE555", [NSNumber numberWithInt:kCVPixelFormatType_16BE555],
           @"kCVPixelFormatType_16LE555", [NSNumber numberWithInt:kCVPixelFormatType_16LE555],
           @"kCVPixelFormatType_16LE5551", [NSNumber numberWithInt:kCVPixelFormatType_16LE5551],
           @"kCVPixelFormatType_16BE565", [NSNumber numberWithInt:kCVPixelFormatType_16BE565],
           @"kCVPixelFormatType_16LE565", [NSNumber numberWithInt:kCVPixelFormatType_16LE565],
           @"kCVPixelFormatType_24RGB", [NSNumber numberWithInt:kCVPixelFormatType_24RGB],
           @"kCVPixelFormatType_24BGR", [NSNumber numberWithInt:kCVPixelFormatType_24BGR],
           @"kCVPixelFormatType_32ARGB", [NSNumber numberWithInt:kCVPixelFormatType_32ARGB],
           @"kCVPixelFormatType_32BGRA", [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],
           @"kCVPixelFormatType_32ABGR", [NSNumber numberWithInt:kCVPixelFormatType_32ABGR],
           @"kCVPixelFormatType_32RGBA", [NSNumber numberWithInt:kCVPixelFormatType_32RGBA],
           @"kCVPixelFormatType_64ARGB", [NSNumber numberWithInt:kCVPixelFormatType_64ARGB],
           @"kCVPixelFormatType_48RGB", [NSNumber numberWithInt:kCVPixelFormatType_48RGB],
           @"kCVPixelFormatType_32AlphaGray", [NSNumber numberWithInt:kCVPixelFormatType_32AlphaGray],
           @"kCVPixelFormatType_16Gray", [NSNumber numberWithInt:kCVPixelFormatType_16Gray],
           @"kCVPixelFormatType_422YpCbCr8", [NSNumber numberWithInt:kCVPixelFormatType_422YpCbCr8],
           @"kCVPixelFormatType_4444YpCbCrA8", [NSNumber numberWithInt:kCVPixelFormatType_4444YpCbCrA8],
           @"kCVPixelFormatType_4444YpCbCrA8R", [NSNumber numberWithInt:kCVPixelFormatType_4444YpCbCrA8R],
           @"kCVPixelFormatType_444YpCbCr8", [NSNumber numberWithInt:kCVPixelFormatType_444YpCbCr8],
           @"kCVPixelFormatType_422YpCbCr16", [NSNumber numberWithInt:kCVPixelFormatType_422YpCbCr16],
           @"kCVPixelFormatType_422YpCbCr10", [NSNumber numberWithInt:kCVPixelFormatType_422YpCbCr10],
           @"kCVPixelFormatType_444YpCbCr10", [NSNumber numberWithInt:kCVPixelFormatType_444YpCbCr10],
           @"kCVPixelFormatType_420YpCbCr8Planar", [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8Planar],
           @"kCVPixelFormatType_420YpCbCr8PlanarFullRange", [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8PlanarFullRange],
           @"kCVPixelFormatType_422YpCbCr_4A_8BiPlanar", [NSNumber numberWithInt:kCVPixelFormatType_422YpCbCr_4A_8BiPlanar],
           @"kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange", [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
           @"kCVPixelFormatType_420YpCbCr8BiPlanarFullRange", [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
           @"kCVPixelFormatType_422YpCbCr8_yuvs", [NSNumber numberWithInt:kCVPixelFormatType_422YpCbCr8_yuvs],
           @"kCVPixelFormatType_422YpCbCr8FullRange", [NSNumber numberWithInt:kCVPixelFormatType_422YpCbCr8FullRange],
        nil];

    for (NSNumber *fmt in [videoOutput availableVideoCVPixelFormatTypes]) {
        NSLog(@"%@", [formats objectForKey:fmt]);
    }
}

@end
