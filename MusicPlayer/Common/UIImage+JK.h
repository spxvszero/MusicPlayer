//
//  UIImage+JK.h
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage(JK)
///模糊图片 radius模糊半径 iteration迭代次数
- (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor;

@end
