# MNNKit

## Introduction

MNNKit is a collection of application-level solutions based on the on-device inference engine [MNN](https://github.com/alibaba/MNN). It's a mature solution after being massively deployed by the MNN team in real world scenarios. MNNKit is mainly for Android/iOS application developers and enables them to rapidly and conveniently deploy AI capabilities to their applications so they can develop new apps or features on top of it.

- Works out of the box. Easy to integrate without prior knowledge of algorithm or model.
- Reliable model and algorithm heavily used and tested in Alibaba's mega-events like double eleven, powered by the stable execution backend MNN.
- Backend-independnet high-performance real-time inference that suits the mobile scenario.

## Hands-on Demo

### 1. Install by scanning QR Code

#### Android

![QR Code](doc/qr_android.png)

### 2. Install from source

```
git clone https://github.com/alibaba/MNNKit.git
```

#### Android

1. Open Android Studio，click File->Open... and choose the directory MNNKitDemo/Android
2. After ``Gradle sync`` completed successfully, click ``Run`` to install it on the real device. (Video detection in the demo relies on Camera)

#### iOS

```
cd MNNKitDemo/iOS
pod update
open MNNKitDemo.xcworkspace
```

And install and run on a real device. (Video detection in the demo relies on Camera)



## SDK Installation

### Kit Dependencies

MNNKit SDK is organized in the following structure：

![SDK Stack](doc/sdk_stack.png)

Divided into three layers from the bottom to the top:

1. MNN Enginer Layer is a prebuilt release version of the [MNN](https://github.com/alibaba/MNN) open-source library on Android/iOS which provides the execution environment of on-device AI.
2. Core layer is layer that provides platform native binding of the underlying MNN library. This layer is a wrapper around of the C++ APIs in Objective-C (iOS) or Java (Android) (both APIs are WIP) as well as providing some public utility class and definitions for the upper-level SDK.
3. Kit layer. FaceRecognition/HandGestureDetection etc are all abstract wrappers of specific algorithms. It contains multiple models and their respective processing. This layer will be expanded with more models and capabilities as time goes on.

### Installation

SDKs at the kit layer are independnet of each other and has implicit dependencies to the required components below it and doesn't need explicit specifications by the end-user.

| Kit SDK              | Android | iOS   | License                                                      |
| -------------------- | ------- | ----- | ------------------------------------------------------------ |
| FaceDetection        | 0.0.2   | 0.0.1 | [《MNN Kit Terms of Service》](https://github.com/alibaba/MNNKitDemo/blob/master/license) |
| HandGestureDetection | 0.0.2   | 0.0.1 | [《MNN Kit Terms of Service》](https://github.com/alibaba/MNNKitDemo/blob/master/license) |
| PortraitSegmentation | 0.0.2   | 0.0.1 | [《MNN Kit Terms of Service》](https://github.com/alibaba/MNNKitDemo/blob/master/license) |

#### Android

- Required minimum API Level 16（Android 4.1）

```groovy
dependencies {
    implementation 'com.alibaba.android.mnnkit:facedetection:0.0.2'
    implementation 'com.alibaba.android.mnnkit:handgesturedetection:0.0.2'
    implementation 'com.alibaba.android.mnnkit:portraitsegmentation:0.0.2'
}
```

##### Proguard

```
-dontwarn com.alibaba.android.mnnkit.**
-keep class com.alibaba.android.mnnkit.**{*;}
```

#### iOS

- Required minimum version iOS 8.0

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios

target 'MNNKitDemo' do
    platform :ios, '8.0'

    pod 'MNNFaceDetection', '~> 0.0.1'
    pod 'MNNHandGestureDetection', '~> 0.0.1'
    pod 'MNNPortraitSegmentation', '~> 0.0.1'

end
```

##### Bitcode

MNNKit SDKs doesn't support Bitcode and you'll need to turn off Bitcode in your application.


## API

There are only three basic APIs in the kit:
  - Create Instance
  - Inference
  - Release Instance
And this is also the sequence for using it, as shown in the graphs below. You can use video/image or other formats of data as the input of the inferencing stage.

![api](doc/api_flow.png)

[FaceDetection API](doc/FaceDetection_CN.md)

[HandGestureDetection API](doc/HandGestureDetection_CN.md)

[PortraitSegmentation API](doc/PortraitSegmentation_CN.md)



## Integration Guide

MNNKit API contains two arguments: ``inAngle`` and ``outAngle``. What are they used for? To answer this question, we should first understand the general process of how the SDK works.
### Sequence of Operations

Below is the sequence to process what the back-facing camera on iOS and Android devices has captured.

![process](doc/process_graph.png)

#### 1. Device preview and output

This stage captures data from the camera and feed it into the SDK while providing proper preview on the screen.

#### 2. Detection in the SDK

MNNKit SDK contains the deep learning models of related algorithms and runs on top of MNN engine. As a result it's not traditional image processing and contains all the characteristics of deep learning. During the training stage, the algorithm uses face images in upright orientation. As a result, this model only recognizes faces in that orientation. If the input contains faces in a different orientation, it might not get detected. We call this ``Content Orientation Sensitive``. In MNNKit, FaceDetection,HandGestureDetection and PortraitSegmentation are all ``Content Orientation Sensitive``.

1. Prior to inferencing with MNN, pre-processing is needed on the raw input to make sure that faces in the raw input image has the correct orientation.
2. The inference process yields results based on the coordinate system of the pre-processed image.
3. To provide easy-to-use results for the caller, the SDK transforms the coordinate system to the same as the screen rendering coordinate system.

> ``inAngle`` in the SDK arguments is to control the angle to rotate so that the raw input in rotated to the required direction and ``outAngle`` is the angle used to rotate the raw inferenced coordinates to the screen rendering coordinate system.

As we can see in the image, if you take a picture with the back camera in portait mode, the image has ``inAngle`` and ``outAngle`` both set to ``0`` for iOS, and for Android it's ``90`` and ``0`` respectively.

#### 3. Result rendering

The final result of the SDK is the description of the feature points, or the coordinate of the feature points to put it simply. All these coordinates are related to the image coordinate system, which uses the top-left point of image as the origin. For example, if the input image is of resolution ``1280*720``, then the result coordinates are also based on this exact coordinate system.

In real world applications, the resulting feature points are supposed to be displayed on the user's screen. The frontend would use a canvas for rendering which could be a view in the UI that is used for displaying or it could be some other components. The size of the canvas is specified by the application itself based on UI design. The coordinate system of this canvas is called rendering coordinates. What this step is doing is to convert the feature points from the image's coordinate system to rendering coordinate system.

In the last step of the SDK's detection process, we've already transformed the feature points into the same orientation as the rendering coordinate system. Since the size of the two coordinate system is different, all that's left to do is to scale the coordinates accordingly followed by rendering them to the canvas and finish the whole process.

### Best Practice

In the aforementioned example, we used the back camera in the upright orientation as an example and is relatively easy. However in real world applications, camera angle, device rotation and some other elements might change the direction of the image and need to be resolved outside the SDK.

MNNKit Demo contains solutions to many of those problems in practice, such as input image angle, camera preview, result rendering, auto-rotation and should be as a best practice guide. If you are unfamiliar with how to deal with these problems, please read coding samples in the demo. We believe that'll solve all your problems.

## License

[《MNN Kit Terms of Service》](https://github.com/alibaba/MNNKitDemo/blob/master/license)
