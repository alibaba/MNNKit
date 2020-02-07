

Gesture detection is a mobile AI solution SDK provided by MNNKit which provides accurate and real-time gesture detection and recognition capabilities. Application developers can develop AI / AR Applications with it.

## Detection Content

#### 1. Hand Position

- Rectangle coordinates of hand position
- Confidence

#### 2. Hand Gesture

![hand3](hand_gesture.png)

## API

### Android

#### 1. Creating an Instance

HandGestureDetector instances are created asynchronously and are called back in the main thread.

##### Arguments

- context：Context

- createConfig: Configuration arguments for creation that could be used to configure if it's being used for video creation and image creation.
- listener: Callback after construction is completed

```java
public static void createInstanceAsync (Context context, HandCreateConfig createConfig, InstanceCreatedListener<HandGestureDetector> listener)
```
> The detector will do Hand detection and HandGesture detection at the same time. The detection is to find the location of the hand and tracking is to relocate its location after the hand has moved. Under video mode the inference is detected by default every 20 frames instead of frame-by-frame and the rest of the frames are only used for tracking. Under image mode each call will trigger the inferencing process and suitale for image detection process.

#### 2.1 Perform Inference on Data Byte Array

The generic byte array data inference supports multiple data input formats. In the case of video stream detection, the camera's callback data could be used as the input to this API.

##### Arguments

- data: Input data, such as the NV21 data from the Camera callback.
- width: Data width
- height: Data height
- format: [Data Format](#支持输入的数据格式)
- inAngle: Input angle, the clock-wise rotation angle that's going to be applied on the input image. Upon rotation the hand should be in the top-to-bottom direction. Please refer to the [Integration Guide](https://github.com/alibaba/MNNKit#接入指南)&[Demo](https://github.com/alibaba/MNNKit/blob/master/Android/app/src/main/java/com/alibaba/android/mnnkit/demo/HandGestureDetectionActivity.java)
- outAngle: Output angle, the output angle that transforms the coordinate system of the raw output feature points to a coordinate system that could be used by the rendering system. Please refer to the [Integration Guide](https://github.com/alibaba/MNNKit#接入指南)&[Demo](https://github.com/alibaba/MNNKit/blob/master/Android/app/src/main/java/com/alibaba/android/mnnkit/demo/HandGestureDetectionActivity.java)
- flipType: Type of the flipping process applied on the resulting feature points:
  - NONE (FLIP_NONE)
  - X-axis flipping (FLIP_X)
  - Y-axis flipping (FLIP_Y)
  - Center flipping (FLIP_XY)
Please reference to [Demo](https://github.com/alibaba/MNNKit/blob/master/Android/app/src/main/java/com/alibaba/android/mnnkit/demo/HandGestureDetectionActivity.java)

##### Return values

Detection objects that might also contain the result of FaceDetection. See [**HandGestureDetectionReport**](#handgesturedetectionreport)

```java
public synchronized HandGestureDetectionReport[] inference(byte[] data, int width, int height, MNNCVImageFormat format, int inAngle, int outAngle, MNNFlipType flipType)
```

#### 2.2 Inferencing an Image

Bitmap detection API. Arguments are the same except the input data is a ``Bitmap``

Note: *If detecting a single image, the SDK should have been configured as Image Detection Mode during construction*.

```java
public synchronized HandGestureDetectionReport[] inference(Bitmap bitmap, int inAngle, int outputAngle, MNNFlipType outputFlip)
```

#### 3. Release

HandGestureDetector instance should have been manually released if it's no longer needed to prevent native memory leak.

```java
public synchronized void release()
```

#### Appendix: Arguments

##### Supported Input Data Format

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
     * 0：Finger Heart
     * 1：五指张开
     * 2：竖食指
     * 3：握拳
     * 4：竖大拇指
     * 5：其他
     */
    public final int label;    // label of detected object
    public final float score;  // score of detected object
    public final int id;       // id for each detected object

    public final float left;
    public final float top;
    public final float right;
    public final float bottom;
		...
}
```



### iOS

#### 1. Creating an Instance

Creating an ``MNNHandGestureDetector`` instance asynchronously

##### Arguments

- config: Configuration arguments for creation that could be used to configure if it's being used for video creation and image creation.
- block: Callback after construction is completed
- callbackQueue: Thread for calling the callback. Default to main thread if this is nil.

```objective-c
+ (void)createInstanceAsync:(MNNHandGestureDetectorCreateConfig*)config Callback:(void(^)(NSError *error, MNNHandGestureDetector *handgestureDetector))block CallbackQueue:(dispatch_queue_t)callbackQueue;
```

```objective-c
+ (void)createInstanceAsync:(MNNHandGestureDetectorCreateConfig*)config Callback:(void(^)(NSError *error, MNNHandGestureDetector *handgestureDetector))block;
```


#### 2.1 Inference (PixelBuffer Input)

This API could be used when using the system camera as input

##### Arguments

- pixelBuffer: Input data of format CVPixelBufferRef
- inAngleInput: angle, the clock-wise rotation angle that's going to be applied on the input image. Upon rotation the hand should be in the top-to-bottom direction. Please refer to the [Integration Guide](https://github.com/alibaba/MNNKit#接入指南)&[Demo](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
- outAngle: Output angle, the output angle that transforms the coordinate system of the raw output feature points to a coordinate system that could be used by the rendering system. Please refer to the [Integration Guide](https://github.com/alibaba/MNNKit#接入指南)&[Demo](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
- flipType: Type of the flipping process applied on the resulting feature points:
  - NONE (FLIP_NONE)
  - X-axis flipping (FLIP_X)
  - Y-axis flipping (FLIP_Y)
  - Center flipping (FLIP_XY)
Please reference to [Demo](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
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
