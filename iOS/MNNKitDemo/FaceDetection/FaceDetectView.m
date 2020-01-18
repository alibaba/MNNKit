//
//  FaceDetectView.m
//  MNNKitDemo
//
//  Created by tsia on 2019/12/24.
//  Copyright © 2019 tsia. All rights reserved.
//

#import "FaceDetectView.h"
#import <MNNFaceDetection/MNNFaceDetector.h>

#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

@interface FaceDetectView()

@property (nonatomic, strong) UILabel *lbYpr;
@property (strong, nonatomic) UILabel *lbFaceAction;

@end

@implementation FaceDetectView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        self.lbYpr = [[UILabel alloc] init];
        self.lbYpr.textColor = [UIColor greenColor];
        self.lbYpr.numberOfLines = 0;
        [self addSubview:self.lbYpr];
        
        self.lbFaceAction = [[UILabel alloc] init];
        self.lbFaceAction.textColor = [UIColor greenColor];
        self.lbFaceAction.numberOfLines = 1;
        self.lbFaceAction.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.lbFaceAction];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = [self.lbYpr sizeThatFits:CGSizeMake(150, CGFLOAT_MAX)];
    self.lbYpr.frame = CGRectMake(self.frame.size.width-size.width-4, self.uiOffsetY+4, size.width, size.height);
    
    size = [self.lbFaceAction sizeThatFits:CGSizeMake(CGFLOAT_MAX, 30)];
    self.lbFaceAction.frame = CGRectMake(self.frame.size.width-size.width-8, CGRectGetMaxY(self.lbYpr.frame)+10, size.width, size.height);
}

-(void)setUseRedColor:(BOOL)useRedColor {
    _useRedColor = useRedColor;
    
    if (useRedColor) {
        self.lbYpr.textColor = [UIColor redColor];
    }
}

-(void)drawRect:(CGRect)rect {
    
    //获得处理的上下文
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //设置线条样式
    CGContextSetLineCap(ctx, kCGLineCapSquare);
    
    if (_useRedColor) {
        CGContextSetRGBStrokeColor(ctx, 1.0, 0.0, 0.0, 1.0);
    } else {
        CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, 1.0);
    }
    //设置线条粗细宽度
    CGContextSetLineWidth(ctx, 1);
    
    float w = self.presetSize.width;
    float h = self.presetSize.height;
    if (ScreenWidth>ScreenHeight) {
        w = self.presetSize.height;
        h = self.presetSize.width;
    }
    float kw = self.frame.size.width/w;
    float kh = self.frame.size.height/h;
    
    for(int i = 0; i < _detectResult.count; i++) {
        MNNFaceDetectionReport *outputModel = _detectResult[i];
        int x = outputModel.rect.origin.x *kw;
        int y = outputModel.rect.origin.y *kh;
        int w = outputModel.rect.size.width *kw;
        int h = outputModel.rect.size.height *kh;
        
        CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
        
        for (int j = 0; j < 106; j++) {
            int p_x = outputModel.keyPoints[j].x *kw;
            int p_y = outputModel.keyPoints[j].y *kh;
            if (outputModel.visibilities[j] > 0) {
                if (_useRedColor) {
                    CGContextSetRGBFillColor(ctx, 1.0, 0.0, 0.0, 1.0);
                } else {
                    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
                }
            } else {
                CGContextSetRGBFillColor(ctx, 0.2, 0.2, 1.0, 1.0);
            }
            CGContextAddArc(ctx, p_x, p_y, 1.5, 0, 2 * M_PI, 0);
            CGContextDrawPath(ctx, kCGPathFill);
            
            if (self.showPointOrder) {
                NSString *str = [NSString stringWithFormat:@"%d", j];
                UIFont *font = [UIFont systemFontOfSize:9.0];
                NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
                [paragraphStyle setAlignment:NSTextAlignmentCenter];
                CGRect iRect = CGRectMake(p_x-10, p_y-11, 22, 25);
                UIColor *color = [UIColor redColor];
                [str drawInRect:iRect withAttributes:@{NSFontAttributeName:font,NSParagraphStyleAttributeName:paragraphStyle,NSForegroundColorAttributeName:color}];
            }
        }
        
        // score
        NSString *str = [NSString stringWithFormat:@"%f", outputModel.score];
        UIFont *font = [UIFont systemFontOfSize:14.0];
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setAlignment:NSTextAlignmentLeft];
        CGRect iRect = CGRectMake(x, y-16, w, 20);
        UIColor *color = _useRedColor?[UIColor redColor]:[UIColor whiteColor];
        [str drawInRect:iRect withAttributes:@{NSFontAttributeName:font,NSParagraphStyleAttributeName:paragraphStyle,NSForegroundColorAttributeName:color}];
        
    }
}

-(void)setDetectResult:(NSArray<MNNFaceDetectionReport *> *)detectResult {
    _detectResult = detectResult;
    
    if (detectResult.count>0) {
        MNNFaceDetectionReport *faceResult = detectResult[0];
        _lbYpr.text = [NSString stringWithFormat:@"yaw: %f\npitch: %f\nrool: %f", faceResult.yaw, faceResult.pitch, faceResult.roll];
        _lbFaceAction.text = [[self faceActionDesps:faceResult] componentsJoinedByString:@"、"];
    } else {
        _lbYpr.text = @"";
        _lbFaceAction.text = @"";
    }
    
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

- (NSArray*)faceActionDesps:(MNNFaceDetectionReport*)faceResult {
    
    NSMutableArray *actions = [NSMutableArray array];
    
    unsigned long faceAction = faceResult.faceAction;
    if ((faceAction & EYE_BLINK)!=0) {
        [actions addObject:@"眨眼"];
    }
    if ((faceAction & MOUTH_AH)!=0) {
        [actions addObject:@"嘴巴大张"];
    }
    if ((faceAction & HEAD_YAW)!=0) {
        [actions addObject:@"摇头"];
    }
    if ((faceAction & HEAD_PITCH)!=0) {
        [actions addObject:@"点头"];
    }
    if ((faceAction & BROW_JUMP)!=0) {
        [actions addObject:@"眉毛挑动"];
    }
    
    return actions;
}

@end
