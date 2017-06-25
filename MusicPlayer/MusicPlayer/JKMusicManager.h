//
//  JKMusicManager.h
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JKMusicListData.h"

typedef enum
{
    MusicPlayStatePlaying,
    MusicPlayStatePause
} MusicPlayState;

typedef enum
{
    MusicPlayLoopModeMin,
    MusicPlayLoopModeOne = MusicPlayLoopModeMin,
    MusicPlayLoopModeList,
    /*
     这里以后可以添加其他循环模式
     */
    MusicPlayLoopModeMax = MusicPlayLoopModeList
} MusicPlayLoopMode;


#define kRecordPlayState @"playState"
#define kRecordPlayIndex @"playIndex"
#define kRecordPlayItemID @"playItemID"
#define kRecordPlayProgress @"playProgress"
#define kRecordPlayTotalTime @"playTotalTime"


@class JKMusicManager;

@protocol JKMusicManagerDelegate <NSObject>

@optional
- (void)musicManager:(JKMusicManager *)manager playingMusicInProgress:(CGFloat)progress;
- (void)musicManager:(JKMusicManager *)manager bufferingMusicInProgress:(CGFloat)progress;
- (void)musicManager:(JKMusicManager *)manager upDateAlbumImage:(UIImage *)image;

- (void)musicManagerBeginPlaying:(JKMusicManager *)manager;
- (void)musicManagerStopPlaying:(JKMusicManager *)manager;
- (void)musicManagerDidFinishPlaying:(JKMusicManager *)manager;

@end


@interface JKMusicManager : NSObject

//当前播放器的状态
@property(nonatomic,assign,readonly) MusicPlayState state;
//当前播放器的循环模式
@property(nonatomic,assign,readonly) MusicPlayLoopMode loopMode;
@property(nonatomic,weak) id<JKMusicManagerDelegate> delegate;

+ (instancetype)defaultManager;

- (void)playAndPause;
- (void)stop;
- (void)next;
- (void)previous;

- (void)seekTimeWithProgress:(CGFloat)progress;

- (BOOL)isPlaying;

- (void)readListFormLocalDisk;

- (void)doNothing;

//播放指定下标的歌曲
- (void)playAtIndex:(NSInteger)index;

//登出时候清除所有内存信息
- (void)clearAllInfoWhenLogout;

#pragma mark - 播放器相关

//添加歌曲列表在主模块，会自动播放
- (BOOL)addMusicItemListDataInMainMode:(JKMusicListData *)list;

//获取正在播放的歌曲下标
- (NSInteger)obtainCurrentMainPlayingIndex;

//获取正在播放的歌曲时间总长
- (CGFloat)obtainTotalTime;
//获取当前正在缓冲的百分比
- (CGFloat)currentBuffering;
//获取专辑标题
- (NSString *)obtainAlbumTitle;
//获取正在播放的歌单
- (NSMutableArray *)obtianCurrentMainPlayerList;
//获取指定下标的歌曲信息
- (JKMusicListDataItem *)obtainMusicItemAtIndex:(NSInteger)index;
//获取当前正在播放的音乐
- (JKMusicListDataItem *)obtainCurrentMainMusicItem;
///每调用一次，会切换到下一个循环模式
- (void)changeLoopMode;

//获取歌曲专辑图片
- (UIImage *)obtainAlbumImage;
- (NSString *)obtainAlbumImageURL;


//减弱或还原音量
- (void)weakVolumn;
- (void)normalVolumn;

@end



