//
//  JKMusicSlider.h
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JKMusicSlider : UISlider

@property(nonatomic,strong) UIColor *unbufferedColor;
@property(nonatomic,strong) UIColor *bufferedColor;
@property(nonatomic,strong) UIColor *readColor;

/*0.00~1.00*/
@property(nonatomic,assign) CGFloat buffering;


@end
