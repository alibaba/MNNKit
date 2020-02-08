

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

#### 2.1 Inference Data

The generic data inference supports multiple format of data input. In a video stream detection scene, the camera's callback data could be used as the input to this API.

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
- error: Error message, if nil the inference succeeded

##### Return value

Object detection result, might contains the results of multiple FaceDetections

```objective-c
- (NSArray<MNNHandGestureDetectionReport *> *)inference:(CVPixelBufferRef)pixelBuffer Angle:(float)inAngle OutAngle:(float)outAngle  FlipType:(MNNFlipType)flipType error:(NSError *__autoreleasing *)error;
```

#### 2.2 Inference (UIImage input)

Image detection input, arguments are the same as above except input data should be UIImage.

Note: *If detecting a single image, the SDK should have been configured as Image Detection Mode during construction*.

```objective-c
- (NSArray<MNNHandGestureDetectionReport *> *)inferenceImage:(UIImage*)image Angle:(float)inAngle OutAngle:(float)outAngle FlipType:(MNNFlipType)flipType error:(NSError *__autoreleasing *)error;
```

#### 2.3 Inference (Generic buffer input)

Inferencing API for generic data.

##### Arguments

- data: Input data represented as unsigned char array.
- w: Width
- h: Height
- format: Data Format of input data
- inAngle: angle, the clock-wise rotation angle that's going to be applied on the input image. Upon rotation the hand should be in the top-to-bottom direction. Please refer to the [Integration Guide](https://github.com/alibaba/MNNKit#接入指南)&[Demo](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
- outAngle: Output angle, the output angle that transforms the coordinate system of the raw output feature points to a coordinate system that could be used by the rendering system. Please refer to the [Integration Guide](https://github.com/alibaba/MNNKit#接入指南)&[Demo](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
- flipType: Type of the flipping process applied on the resulting feature points:
  - NONE (FLIP_NONE)
  - X-axis flipping (FLIP_X)
  - Y-axis flipping (FLIP_Y)
  - Center flipping (FLIP_XY)
Please reference to [Demo](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/HandGestureDetection/HandGestureDetectionViewController.m)
- error: Error message, if nil the inference succeeded

##### Return value

Inference result object, might contain multiple HandGesture Detection results. Ref: [**MNNHandGestureDetectionReport**](#mnnhandgesturedetectionreport)

```objective-c
- (NSArray<MNNHandGestureDetectionReport *> *)inference:(unsigned char*)data Width:(float)w Height:(float)h Format:(MNNCVImageFormat)format Angle:(float)inAngle OutAngle:(float)outAngle FlipType:(MNNFlipType)flipType error:(NSError *__autoreleasing *)error;
```

#### 3. Release

MNNHandGestureDetector automatically triggers related memory release when its lifetime ends.

#### Appendix: Arguments Description

##### Supported input data formats

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
