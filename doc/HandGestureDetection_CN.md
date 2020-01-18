

手势检测是MNNKit提供的移动端AI解决方案SDK，在端上提供了精准实时的手势检测和识别能力，基于它应用可以拓展丰富的业务场景和玩法。

## 检测内容

#### 1. 人手位置

- 人手位置的矩形坐标
- 置信度

#### 2. 手势

![hand3](hand_gesture.png)

## API

### Android

#### 1. 创建实例

异步创建HandGestureDetector实例，主线程中回调。

##### 参数

- context：上下文环境

- createConfig：创建时的配置参数，可用来配置是视频检测还是图片检测
- listener：创建完成后的回调

```java
public static void createInstanceAsync (Context context, HandCreateConfig createConfig, InstanceCreatedListener<HandGestureDetector> listener)
```

>检测器会同时进行人手检测和手势识别，人手检测包含检测和跟踪两个动作，检测就是找到人手的位置，跟踪就是人手移动时重新定位其位置。视频模式下并不是每一帧都检测，默认每20帧检测一次，其余帧只做跟踪，适合视频流输入的场景；而图片模式下每一次调用都会进行检测，适合图片检测的场景。

#### 2.1 推理数据

通用数据的推理，支持多种数据格式输入。视频流检测场景中，可以使用摄像头的回调数据作为该接口的输入。

##### 参数

- data：输入的数据，如Camera回调的NV21数据
- width：数据宽
- height：数据高
- format：data的[数据格式](#支持输入的数据格式)
- inAngle：输入角度，使输入图像顺时针旋转的角度，旋转后人手变为正向，请参考[接入指南](https://github.com/alibaba/MNNKit#接入指南)&[Demo示例](https://github.com/alibaba/MNNKit/blob/master/Android/app/src/main/java/com/alibaba/android/mnnkit/demo/HandGestureDetectionActivity.java)
- outAngle：输出角度，使结果关键点变换坐标系的角度，方便上层渲染使用，请参考[接入指南](https://github.com/alibaba/MNNKit#接入指南)&[Demo示例](https://github.com/alibaba/MNNKit/blob/master/Android/app/src/main/java/com/alibaba/android/mnnkit/demo/HandGestureDetectionActivity.java)
- flipType：使结果关键点镜像类型，不镜像（FLIP_NONE）、沿X轴镜像（FLIP_X）、沿Y轴镜像（FLIP_Y）、中心镜像（FLIP_XY），请参考工程实践[Demo示例](https://github.com/alibaba/MNNKit/blob/master/Android/app/src/main/java/com/alibaba/android/mnnkit/demo/HandGestureDetectionActivity.java)

##### 返回值

检测对象，可能包含对个人脸的检测结果，详见[**HandGestureDetectionReport**](#handgesturedetectionreport)

```java
public synchronized HandGestureDetectionReport[] inference(byte[] data, int width, int height, MNNCVImageFormat format, int inAngle, int outAngle, MNNFlipType flipType)
```

#### 2.2 推理图片

Bitmap检测接口，除了输入数据为bitmap，其余参数一样。

注意：*如检测单个图片，创建时需配置为图片检测模式*。

```java
public synchronized HandGestureDetectionReport[] inference(Bitmap bitmap, int inAngle, int outputAngle, MNNFlipType outputFlip)
```

#### 3. 释放

HandGestureDetector实例用完之后需要手动释放，否则会产生native的内存泄露。

```java
public synchronized void release()
```

#### 附：参数说明

##### 支持输入的数据格式

```java
public enum MNNCVImageFormat {
    RGBA(0),
    RGB(1),
    BGR(2),
    GRAY(3),
    BGRA(4),
    YUV_NV21(11);
  
    ...
}
```

##### HandGestureDetectionReport 

```java
public class HandGestureDetectionReport {
    /**
     * 0：比心
     * 1：五指张开
     * 2：竖食指
     * 3：握拳
     * 4：竖大拇指
     * 5：其他
     */
    public final int label;    // label of detected object
    public final float score;  // score of dtected object
    public final int id;       // id for each detected object

    public final float left;
    public final float top;
    public final float right;
    public final float bottom;
		...
}
```



### iOS

#### 1. 创建实例

异步创建MNNHandGestureDetector实例

##### 参数

- config：创建时的配置参数，可用来配置是视频检测还是图片检测
- block：创建完成后的回调
- callbackQueue：指定回调的线程，如设置nil默认主线程中回调

```objective-c
+ (void)createInstanceAsync:(MNNHandGestureDetectorCreateConfig*)config Callback:(void(^)(NSError *error, MNNHandGestureDetector *handgestureDetector))block CallbackQueue:(dispatch_queue_t)callbackQueue;
```

默认主线程中回调，其他参数一样

```objective-c
+ (void)createInstanceAsync:(MNNHandGestureDetectorCreateConfig*)config Callback:(void(^)(NSError *error, MNNHandGestureDetector *handgestureDetector))block;
```

> 检测器会同时进行人手检测和手势识别，人手检测包含检测和跟踪两个动作，检测就是找到人手的位置，跟踪就是人手移动时重新定位其位置。视频模式下并不是每一帧都检测，默认每20帧检测一次，其余帧只做跟踪，适合视频流输入的场景；而图片模式下每一次调用都会进行检测，适合图片检测的场景。

#### 2.1 推理（PixelBuffer输入）

使用系统相机作为输入检测时可使用该接口

##### 参数

- pixelBuffer：输入数据，CVPixelBufferRef格式
- inAngle：输入角度，使输入图像顺时针旋转的角度，旋转后人脸变为正向，请参考[接入指南](https://github.com/alibaba/MNNKit#接入指南)&[Demo示例](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
- outAngle：输出角度，使结果关键点变换坐标系的角度，方便上层渲染使用，请参考[接入指南](https://github.com/alibaba/MNNKit#接入指南)&[Demo示例](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
- flipType：使结果关键点镜像类型，不镜像（FLIP_NONE）、沿X轴镜像（FLIP_X）、沿Y轴镜像（FLIP_Y）、中心镜像（FLIP_XY），请参考工程实践[Demo示例](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
- error：错误信息，如果是nil代表推理成功

##### 返回值

检测结果对象，可能包含多个人脸检测的结果

```objective-c
- (NSArray<MNNHandGestureDetectionReport *> *)inference:(CVPixelBufferRef)pixelBuffer Angle:(float)inAngle OutAngle:(float)outAngle  FlipType:(MNNFlipType)flipType error:(NSError *__autoreleasing *)error;
```

#### 2.2 推理（UIImage输入）

图片检测接口，除了输入数据为UIImage，其余参数一样。

注意：*如检测单个图片，创建时需配置为图片检测模式*。

```objective-c
- (NSArray<MNNHandGestureDetectionReport *> *)inferenceImage:(UIImage*)image Angle:(float)inAngle OutAngle:(float)outAngle FlipType:(MNNFlipType)flipType error:(NSError *__autoreleasing *)error;
```

#### 2.3 推理（通用buffer数组输入）

通用数据的推理接口

##### 参数

- data：输入数据，通用数据表示为unsigned char数组
- w：数据宽
- h：数据高
- format：data的[数据格式](#支持输入的数据格式-1)
- inAngle：输入角度，使输入图像顺时针旋转的角度，旋转后人脸变为正向，请参考[接入指南](https://github.com/alibaba/MNNKit#接入指南)&[Demo示例](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
- outAngle：输出角度，使结果关键点变换坐标系的角度，方便上层渲染使用，请参考[接入指南](https://github.com/alibaba/MNNKit#接入指南)&[Demo示例](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
- flipType：使结果关键点镜像类型，不镜像（FLIP_NONE）、沿X轴镜像（FLIP_X）、沿Y轴镜像（FLIP_Y）、中心镜像（FLIP_XY），请参考工程实践[Demo示例](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
- error：错误信息，如果是nil代表推理成功

##### 返回值

检测结果对象，可能包含多个手势检测的结果，详见[**MNNHandGestureDetectionReport**](#mnnhandgesturedetectionreport)

```objective-c
- (NSArray<MNNHandGestureDetectionReport *> *)inference:(unsigned char*)data Width:(float)w Height:(float)h Format:(MNNCVImageFormat)format Angle:(float)inAngle OutAngle:(float)outAngle FlipType:(MNNFlipType)flipType error:(NSError *__autoreleasing *)error;
```

#### 3. 释放

MNNHandGestureDetector实例生命周期结束后会自动触发相关内存的释放，无需调用方手动释放

#### 附：参数说明

##### 支持输入的数据格式

```objective-c
typedef NS_ENUM(NSUInteger, MNNCVImageFormat) {
    RGBA = 0,
    RGB = 1,
    BGR = 2,
    GRAY = 3,
    BGRA = 4,
    YUV_NV21 = 11,
};
```

##### MNNHandGestureDetectionReport

```objective-c
@interface MNNHandGestureDetectionReport : NSObject
/**
label
 0：比心
 1：五指张开
 2：竖食指
 3：握拳
 4：竖大拇指
 5：其他
 */
@property (nonatomic, assign) int label;
@property (nonatomic, assign) float score;
@property (nonatomic, assign) int handID;
@property (nonatomic, assign) CGRect rect;

@end
```



