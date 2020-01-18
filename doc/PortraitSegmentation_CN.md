

人像分割是MNNKit提供的移动端AI解决方案SDK，在端上提供了实时的人像分割能力。

## API

#### 1. 创建实例

异步创建PortraitSegmentor实例，主线程中回调。

##### 参数

- context：上下文环境

- listener：创建完成后的回调

```java
public static void createInstanceAsync (Context context,  InstanceCreatedListener<PortraitSegmentor> listener)
```

#### 2.1 推理数据

通用数据的推理，支持多种数据格式输入。视频流检测场景中，可以使用摄像头的回调数据作为该接口的输入。

##### 参数

- data：输入的数据，如Camera回调的NV21数据
- width：数据宽
- height：数据高
- format：data的[数据格式](#支持输入的数据格式)
- inAngle：输入角度，使输入图像顺时针旋转的角度，旋转后人像变为正向，请参考[接入指南](https://github.com/alibaba/MNNKit#接入指南)&[Demo示例](https://github.com/alibaba/MNNKit/blob/master/Android/app/src/main/java/com/alibaba/android/mnnkit/demo/PortraitSegmentationActivity.java)
- flipType：结果关键点镜像类型，目前只支持沿Y轴左右镜像（FLIP_Y），其他值设置无效

##### 返回值

返回值是一个**216*384**的mask二维数组，数组中的每个值代表在人像区域的得分值，score（0.0~1.0）越大代表在人像区域内的概率越高。

上层可能需要对这个固定大小的mask以及原图做一些图像处理操作，来达到自己的目的，Demo中为演示调用API方便，使用了一种比较简单的方式实现了人像背景替换，实际运用中，不同的图像处理方案最终达到的效果也不同，这是应用开发者需要考虑的。

```java
public synchronized float[] inference(byte[] data, int width, int height, MNNCVImageFormat format, int inAngle, MNNFlipType flipType)
```

> 人像分割API暂不支持outAngle，因为相对于耗时可忽略的关键点坐标变换，mask图变换会消耗较多的时间，考虑到大部分应用都支持手机竖屏的场景，暂时不支持mask图的角度变换。因此人像分割只适合在自动旋转关闭、手机竖屏的应用场景中使用。

#### 2.2 推理图片

Bitmap检测接口，除了输入数据为bitmap，其余参数和返回值含义一样。

```
public synchronized float[] inference(Bitmap bitmap, MNNFlipType flipType)
```

#### 3. 释放

HandGestureDetector实例用完之后需要手动释放，否则会产生native的内存泄露。

```java
public synchronized void release()
```

#### 附：参数说明

#####支持输入的数据格式

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

##### 

### iOS

#### 1. 创建实例

异步创建MNNPortraitSegmentor实例

##### 参数

- block：创建完成后的回调
- callbackQueue：指定回调的线程，如设置nil默认主线程中回调

```objective-c
+ (void)createInstanceAsync:(void(^)(NSError *error, MNNPortraitSegmentor *portraitSegmentor))block CallbackQueue:(dispatch_queue_t)callbackQueue;
```

默认主线程中回调，其他参数一样

```objective-c
+ (void)createInstanceAsync:(void(^)(NSError *error, MNNPortraitSegmentor *portraitSegmentor))block;
```

#### 2.1 推理（PixelBuffer输入）

使用系统相机作为输入检测时可使用该接口

##### 参数

- pixelBuffer：输入数据，CVPixelBufferRef格式
- inAngle：输入角度，使输入图像顺时针旋转的角度，旋转后人脸变为正向，请参考[接入指南](https://github.com/alibaba/MNNKit#接入指南)&[Demo示例](https://github.com/alibaba/MNNKit/blob/master/iOS/MNNKitDemo/PortraitSegmentation/PortraitSegmentationViewController.m)
- outputFlipType：结果关键点镜像类型，目前只支持沿Y轴左右镜像（FLIP_Y），其他值设置无效
- error：错误信息，如果是nil代表推理成功

##### 返回值

返回值是一个**216*384**的mask二维数组，数组中的每个值代表在人像区域的得分值，score（0.0~1.0）越大代表在人像区域内的概率越高。

上层可能需要对这个固定大小的mask以及原图做一些图像处理操作，来达到自己的目的，Demo中为演示调用API方便，使用了一种比较简单的方式实现了人像背景替换，实际运用中，不同的图像处理方案最终达到的效果也不同，这是应用开发者需要考虑的。

```objective-c
- (NSArray<NSNumber*> *)inference:(CVPixelBufferRef)pixelBuffer Angle:(float)inAngle FlipType:(MNNFlipType)outputFlipType error:(NSError *__autoreleasing *)error;
```

> 人像分割API暂不支持outAngle，因为相对于耗时可忽略的关键点坐标变换，mask图变换会消耗较多的时间，考虑到大部分应用都支持手机竖屏的场景，暂时不支持mask图的角度变换。因此人像分割只适合在自动旋转关闭、手机竖屏的应用场景中使用。

#### 2.2 推理（UIImage输入）

图片检测接口，除了输入数据为UIImage，其余参数一样。

```objective-c
- (NSArray<NSNumber*> *)inferenceImage:(UIImage*)image Angle:(float)inAngle FlipType:(MNNFlipType)outputFlipType error:(NSError *__autoreleasing *)error;
```

#### 2.3 推理（通用buffer数组输入）

通用数据的推理接口

##### 参数

- data：输入数据，通用数据表示为unsigned char数组
- w：数据宽
- h：数据高
- format：data的[数据格式](##支持输入的数据格式-1)
- inAngle：输入角度，使输入图像顺时针旋转的角度，旋转后人脸变为正向，请参考[接入指南](https://github.com/alibaba/MNNKit#接入指南)&Demo示例
- outputFlipType：结果关键点镜像类型，目前只支持沿Y轴左右镜像（FLIP_Y），其他值设置无效
- error：错误信息，如果是nil代表推理成功

##### 返回值

返回值是一个**216*384**的mask二维数组，数组中的每个值代表在人像区域的得分值，score（0.0~1.0）越大代表在人像区域内的概率越高。

```objective-c
- (NSArray<NSNumber*> *)inference:(unsigned char*)data Width:(float)w Height:(float)h Format:(MNNCVImageFormat)format Angle:(float)inAngle FlipType:(MNNFlipType)outputFlipType error:(NSError *__autoreleasing *)error;
```

#### 3. 释放

MNNPortraitSegmentor实例生命周期结束后会自动触发相关内存的释放，无需调用方手动释放

#### 附：参数说明

#####支持输入的数据格式

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