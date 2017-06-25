//
//  JKMusicScrollView.h
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import <UIKit/UIKit.h>


@class JKMusicScrollView;

@protocol JKMusicScrollViewDelegate <NSObject>

- (void)musicList:(JKMusicScrollView *)scrollView didClickedAtIndex:(NSUInteger)index;

- (void)musicList:(JKMusicScrollView *)scrollView dragScrollViewOffsetProgress:(CGFloat)progress;

@end



@interface JKMusicListCell : UITableViewCell

@property(nonatomic,assign,getter=isFirstCell) BOOL firstCell;

@property(nonatomic,strong) NSString *musicName;

@end





@interface JKMusicScrollView : UIView

@property(nonatomic,strong) NSMutableArray *musicList;
@property(nonatomic,strong) UIImage *albumImage;
@property(nonatomic,strong) NSString *albumTitle;
//当前页码
@property(nonatomic, assign, readonly) NSUInteger pageIndex;
//当前播放了的下表
@property(nonatomic,assign) NSInteger playingIndex;

@property(nonatomic,weak) id<JKMusicScrollViewDelegate> delegate;

@end
