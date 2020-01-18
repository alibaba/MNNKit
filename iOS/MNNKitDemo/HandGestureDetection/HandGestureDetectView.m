//
//  HandGestureDetectView.m
//  MNNKitDemo
//
//  Created by tsia on 2019/12/25.
//  Copyright © 2019 tsia. All rights reserved.
//

#import "HandGestureDetectView.h"
#import <MNNHandGestureDetection/MNNHandGestureDetector.h>

#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

@implementation HandGestureDetectView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
}

-(void)drawRect:(CGRect)rect {
    
    //获得处理的上下文
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //设置线条样式
    CGContextSetLineCap(ctx, kCGLineCapSquare);
    
    CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, 1.0);
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
    
    for (int i = 0; i < self.detectResult.count; i++) {
        MNNHandGestureDetectionReport *result = _detectResult[i];
        int x = result.rect.origin.x *kw;
        int y = result.rect.origin.y *kh;
        int w = result.rect.size.width *kw;
        int h = result.rect.size.height *kh;
        
        CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
        
        NSString *str = [NSString stringWithFormat:@"%@:%f", [[self class] labelDesp:result.label], result.score];
        UIFont *font = [UIFont systemFontOfSize:16.0];
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setAlignment:NSTextAlignmentLeft];
        CGRect iRect = CGRectMake(x, y-22, w, 28);
        UIColor *color = [UIColor whiteColor];
        [str drawInRect:iRect withAttributes:@{NSFontAttributeName:font,NSParagraphStyleAttributeName:paragraphStyle,NSForegroundColorAttributeName:color}];
    }
}

-(void)setDetectResult:(NSArray<MNNHandGestureDetectionReport *> *)detectResult {
    _detectResult = detectResult;
    
    [self setNeedsDisplay];
}

+ (NSString*)labelDesp:(int)label {
    
    NSString *desc = @"其他";
    switch (label) {
        case 0:
            desc = @"比心";
            break;
        case 1:
            desc = @"手部张开";
            break;
        case 2:
            desc = @"竖食指";
            break;
        case 3:
            desc = @"拳头";
            break;
        case 4:
            desc = @"竖大拇指";
            break;
        case 5:
            desc = @"其他";
            break;
            
        default:
            break;
    }
    
    return desc;
}

@end
