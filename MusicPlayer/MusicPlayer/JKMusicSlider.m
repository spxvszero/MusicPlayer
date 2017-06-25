//
//  JKMusicSlider.m
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import "JKMusicSlider.h"

@implementation JKMusicSlider

- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    rect = CGRectInset(rect, 0, rect.size.height * 0.3);
    
    [self.unbufferedColor set];
    CGContextFillRect(ctx, rect);
    
    [self.bufferedColor set];
    ///计算百分比
    CGFloat width = rect.size.width * self.buffering;
    CGContextFillRect(ctx, CGRectMake(rect.origin.x, rect.origin.y, width, rect.size.height));
    
    [self.readColor set];
    CGFloat process = self.value/(self.maximumValue- self.minimumValue);
    CGContextFillRect(ctx, CGRectMake(rect.origin.x, rect.origin.y, 2 + process * (rect.size.width - 2), rect.size.height));
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.minimumTrackTintColor = [UIColor clearColor];
        self.maximumTrackTintColor = [UIColor clearColor];
    }
    return self;
}


- (void)setBuffering:(CGFloat)buffering
{
    _buffering = buffering;
    
    [self setNeedsDisplay];
}


- (void)setValue:(float)value animated:(BOOL)animated
{
    [super setValue:value animated:animated];
    [self setNeedsDisplay];
}

@end
