//
//  VideoBaseDetectView.h
//  MNNKitDemo
//
//  Created by tsia on 2019/12/26.
//  Copyright © 2019 tsia. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoBaseDetectView : UIView

@property (nonatomic, assign) float uiOffsetY;// 子控件布局的起始位置
@property (nonatomic, assign) CGSize presetSize;// 图像分辨率

@end

NS_ASSUME_NONNULL_END
