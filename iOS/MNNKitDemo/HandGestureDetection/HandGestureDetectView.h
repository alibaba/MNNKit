//
//  HandGestureDetectView.h
//  MNNKitDemo
//
//  Created by tsia on 2019/12/25.
//  Copyright © 2019 tsia. All rights reserved.
//

#import "VideoBaseDetectView.h"

NS_ASSUME_NONNULL_BEGIN

@class MNNHandGestureDetectionReport;
@interface HandGestureDetectView : VideoBaseDetectView

@property (nonatomic, strong) NSArray<MNNHandGestureDetectionReport*> *detectResult;

@end

NS_ASSUME_NONNULL_END
