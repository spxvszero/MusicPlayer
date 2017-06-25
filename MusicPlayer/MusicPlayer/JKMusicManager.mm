//
//  JKMusicManager.m
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import "JKMusicManager.h"
#import "JKNotificationDefine.h"

#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMusicPlayerController.h>
#import <AVFoundation/AVFoundation.h>

#import "SDWebImageManager.h"
#import "FSAudioController.h"
#import "FSPlaylistItem.h"
#import "Reachability.h"
#import "NSMutableObject+SafeInsert.h"
#import "JKMusicFileStorageManager.h"
#import "JKMusicListData.h"


@interface JKMusicManager()<FSAudioControllerDelegate>
//播放列表
@property(nonatomic,strong) NSMutableArray *playList;
//播放器
@property(nonatomic,strong) FSAudioController *audioController;
//播放器配置
@property(nonatomic,strong) FSStreamConfiguration *configuration;
//播放时间观察器
@property(nonatomic,strong) NSTimer *timer;
//正在播放的下标
@property(nonatomic,assign) NSInteger playingIndex;
//专辑图片
@property(nonatomic,strong) UIImage *albumImage;
//专辑图片url
@property(nonatomic,strong) NSString *albumImageURL;
//专辑标题
@property(nonatomic,strong) NSString *albumTitle;
//当前歌曲的时间长度
@property(nonatomic,strong) NSString *totalTime;
//记录停止状态
@property(nonatomic,assign) BOOL stopped;
//要是出现重试失败的情况
@property(nonatomic,assign) BOOL tryWhenFailed;
//网络状态
@property(nonatomic,strong) Reachability *reachNet;
//记录先前的网络状态
@property(nonatomic,assign) NetworkStatus netType;
//第三方播放器需要用到的歌曲item
@property(nonatomic,strong) NSMutableArray<FSPlaylistItem *> *itemList;
//用于区别是否需要禁用用户点击播放按钮的值，当值小于2的时候，说明还未进入到播放状态
//此时禁止用户点击，当值大于等于2的时候，说明已经处于或者已经进入过播放状态，这时
//允许用户点击播放
@property(nonatomic,assign) int playLevel;

///这里原生播放器，当第三方播放失败的时候调用
@property(nonatomic,strong) AVPlayer *player;

///第三方的坑，缓冲完成之前如果暂停歌曲，缓冲完成会自动切成播放中的状态，然而实际并不能播放
@property(nonatomic,assign) BOOL cancelPlay;
///上面那个坑引发的另一个坑，因为自动切换成播放中状态的问题，导致这边isPlaying判断不准确，这个变量是强行把状态扭回来的＝＝
@property(nonatomic,assign) BOOL ajustPlayBtn;
///...嗯，一样的，为了准确而设，本地有缓存，状态会从正在缓冲直接到播放中，上面的等于白做了
@property(nonatomic,assign) BOOL localCached;
///呵呵。。。。
@property(nonatomic,assign) BOOL ajustPause;
///又来了一个咯
@property(nonatomic, assign) BOOL changeModeFlag;


//是否需要跳转进度
@property(nonatomic,assign) BOOL needSeekProgress;
//跟随上一个变量，跳转进度的位置
@property(nonatomic,assign) CGFloat aimProgress;

@end

@implementation JKMusicManager

- (BOOL)addMusicItemListDataInMainMode:(JKMusicListData *)list
{
    [self resetStatusFlag];
    [self removeNativePlayer];
    if ([self isPlaying]) {
        [self playAndPause];
    }
    self.playList = [NSMutableArray arrayWithArray:list.song_list];
    self.albumTitle = list.name;
    self.playingIndex = list.index;
    self.albumImageURL = list.image;
    self.totalTime = [[self.playList safeObjectAtIndex:self.playingIndex] song_time];
    
    [self converItems];
    
    self.localCached = [JKMusicFileStorageManager checkMusicCachedFileIntegrityWith:self.playList[self.playingIndex]];
    
    [self.audioController playFromPlaylist:self.itemList itemIndex:self.playingIndex];
    
    [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:list.image] options:SDWebImageRetryFailed progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        self.albumImage = image ?: [UIImage imageNamed:@"musicPlayer_albumDefaultImage.png"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateAlbumImage];
        });
    }];
    
    
    return YES;
}


- (MusicPlayState)state
{
    if ([self.audioController isPlaying]) {
        return MusicPlayStatePlaying;
    }else{
        return MusicPlayStatePause;
    }
}

#pragma mark - 播放控制

- (void)seekTimeWithProgress:(CGFloat)progress
{
    if (self.player) {
        [self.player seekToTime:CMTimeMake(progress * [self.totalTime integerValue], 44100)];
        return;
    }
    //    FSStreamPosition pos = {0};
    //    pos.position = progress * ((CGFloat)[self.totalTime integerValue] / self.audioController.activeStream.duration.playbackTimeInSeconds);
    //    [self.audioController.activeStream seekToPosition:pos];
    [self performSelector:@selector(seekProgress:) withObject:@(progress) afterDelay:0.1];
}

- (void)seekProgress:(NSNumber *)prog
{
    CGFloat progress = [prog doubleValue];
    FSStreamPosition pos = {0};
    pos.position = progress * ((CGFloat)[self.totalTime integerValue] / self.audioController.activeStream.duration.playbackTimeInSeconds);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.audioController.activeStream seekToPosition:pos];
    });
}


- (void)playAndPause
{
    
    [self playOutside];
    ///本地播放
    if (self.player) {
        self.player.rate == 1 ? [self.player pause] : [self.player play];
        [self updateScreenMusicInfo];
        return;
    }
    
    if (self.ajustPlayBtn) {
        self.ajustPlayBtn = NO;
    }
    
    ///第三方播放
    if (self.audioController.activeStream.currentTimePlayed.playbackTimeInSeconds <= 0 || self.stopped)
    {///无法播放的状态
        
        if (self.itemList.count == 0)
        {
            return;
        }
        [self.audioController playItemAtIndex:self.playingIndex];
        NSLog(@"play failed,retry play at index :%ld",(long)self.playingIndex);
    }
    else
    {///播放中的状态
        [self.audioController pause];
    }
    [self updateScreenMusicInfo];
}

- (void)stop
{
    if (self.player) {
        [self removeNativePlayer];
        return;
    }
    [self.audioController stop];
}

- (void)next
{
    if (self.playList.count <= 0)
    {
        NSLog(@"NULL music List exist!");
        return;
    }
    
    if (self.player) {
        [self removeNativePlayer];
    }
    

    if (self.playingIndex >= (self.playList.count -1)) {
        self.playingIndex = 0;
        self.localCached = [JKMusicFileStorageManager checkMusicCachedFileIntegrityWith:self.playList[self.playingIndex]];
        [self.audioController playItemAtIndex:self.playingIndex];
        
    }else{
        self.playingIndex = self.playingIndex + 1;
        self.localCached = [JKMusicFileStorageManager checkMusicCachedFileIntegrityWith:self.playList[self.playingIndex]];
        [self.audioController playNextItem];
    }
    
    NSLog(@"Next click,current playingIndex ---- %ld",(long)self.playingIndex);
}

- (void)previous
{
    if (self.player) {
        [self removeNativePlayer];
    }
    
    if (self.playingIndex <= 0) {
        self.playingIndex = self.playList.count - 1;
        self.localCached = [JKMusicFileStorageManager checkMusicCachedFileIntegrityWith:self.playList[self.playingIndex]];
        [self.audioController playItemAtIndex:self.playingIndex];
    }else{
        self.playingIndex = self.playingIndex - 1;
        self.localCached = [JKMusicFileStorageManager checkMusicCachedFileIntegrityWith:self.playList[self.playingIndex]];
        [self.audioController playPreviousItem];
    }
    NSLog(@"Previous click,current playingIndex ---- %ld",(long)self.playingIndex);
    
    
}

- (void)playAtIndex:(NSInteger)index
{
    if (self.player) {
        [self removeNativePlayer];
    }
    self.playingIndex = index;
    self.localCached = [JKMusicFileStorageManager checkMusicCachedFileIntegrityWith:[self.playList safeObjectAtIndex:self.playingIndex]];
    [self.audioController playItemAtIndex:index];
}

- (BOOL)isPlaying
{
    if (self.player) {
        return self.player.rate == 1;
    }else{
        if (self.ajustPlayBtn && self.ajustPause) {
            return NO;
        }
        return [self.audioController isPlaying];
    }
    //    return self.player ? self.player.rate == 1 : [self.audioController isPlaying];
}

- (CGFloat)obtainTotalTime
{
    return [self.totalTime integerValue];
}

- (CGFloat)currentBuffering
{
    if (!self.audioController.currentPlaylistItem) {
        return 0;
    }
    return self.audioController.activeStream.totalCachedObjectsSize/self.audioController.activeStream.contentLength;
}

- (NSMutableArray *)obtianCurrentMainPlayerList
{
    return self.playList;
}

- (UIImage *)obtainAlbumImage
{
    return self.albumImage;
}

- (NSString *)obtainAlbumImageURL
{
    return self.albumImageURL;
}


- (NSString *)obtainAlbumTitle
{
    return self.albumTitle;
}

- (NSInteger)obtainCurrentMainPlayingIndex
{
    return self.playingIndex;
}


- (JKMusicListDataItem *)obtainCurrentMainMusicItem
{
    if (self.playList.count <= [self obtainCurrentMainPlayingIndex]) {
        NSLog(@"playing index is not correct with list count :%zd index :%zd",self.playList.count,self.playingIndex);
        return nil;
    }
    return [self.playList safeObjectAtIndex:[self obtainCurrentMainPlayingIndex]];
}

- (JKMusicListDataItem *)obtainMusicItemAtIndex:(NSInteger)index
{
    if (index > self.playList.count - 1 || index < 0) {
        NSLog(@"obtain music item at index %ld is not in list count %zd",(long)index ,self.playList.count);
        return nil;
    }
    
    return self.playList[index];
}

//更新时间
- (void)updatePlaybackProgress
{
    if (!self.delegate) {
        [self.timer invalidate];
        self.timer = nil;
        return;
    }
    
    if (self.totalTime.intValue <= 0) {
        self.totalTime = [NSString stringWithFormat:@"%f",self.audioController.activeStream.duration.playbackTimeInSeconds];
    }
    
//        FSSeekByteOffset offset = self.audioController.activeStream.currentSeekByteOffset;
//        NSLog(@"\naudioStream === defaultContentLength : %llu \n\
    contentLength  :  %llu \n\
    currentSeekByteOffset.position  : %f\n\
    localCachedObjectsSize  :  %llu\n\
    currentTimePlayed  :  %u --- %u ---- %f\n\
    playbackTimeInSeconds  :  %u --- %u ---- %f\n",self.audioController.activeStream.defaultContentLength,self.audioController.activeStream.contentLength, offset.position,[self.audioController.activeStream getCachedSizeWithURLStr:[self obtainCurrentMainMusicItem].url],self.audioController.activeStream.currentTimePlayed.minute,self.audioController.activeStream.currentTimePlayed.second,self.audioController.activeStream.currentTimePlayed.playbackTimeInSeconds,self.audioController.activeStream.duration.minute,self.audioController.activeStream.duration.second,self.audioController.activeStream.duration.playbackTimeInSeconds);
    
    if (!self.player)
    {//第三方播放器
        ////缓冲
        if (self.audioController.activeStream.contentLength > 0)
        {
            
            NSString *urlStr = [self obtainCurrentMainMusicItem].url;
            
            // A non-continuous stream, show the buffering progress within the whole file
            CGFloat cacheProcess = self.audioController.activeStream.contentLength == 0?0:(CGFloat)[self.audioController.activeStream getCachedSizeWithURLStr:urlStr] / (CGFloat)self.audioController.activeStream.contentLength;
            
            [self bufferingProgressChange:cacheProcess];
        }
        else
        {
            // A continuous stream, use the buffering indicator to show progress
            // among the filled prebuffer
            [self bufferingProgressChange:(float)self.audioController.activeStream.prebufferedByteCount / self.configuration.maxPrebufferedByteCount];
        }
        
        //正在播放
        [self playProgessChange:self.audioController.activeStream.currentTimePlayed.playbackTimeInSeconds/(CGFloat)[self.totalTime integerValue]];
    }
    else
    {
        //本地播放器
        [self bufferingProgressChange:0];
        CGFloat progress = CMTimeGetSeconds(self.player.currentTime)/(CGFloat)[self.totalTime integerValue];
        [self playProgessChange:progress];
        
        if (progress >= 1) {
            [self removeNativePlayer];
            [self playBackCompleted];
        }
    }
}

//类型转换
- (void)converItems
{
    [self.itemList removeAllObjects];
    self.itemList = nil;
    for (JKMusicListDataItem *origin in self.playList) {
        FSPlaylistItem *item = [[FSPlaylistItem alloc] init];
        item.title = origin.name;
        item.url = [NSURL URLWithString:origin.url];
        [self.itemList safeAddObject:item];
    }
}

- (void)weakVolumn
{
    self.audioController.activeStream.volume = 0.3f;
}

- (void)normalVolumn
{
    self.audioController.activeStream.volume = 1.f;
}


- (void)changeLoopMode
{
    _loopMode = (self.loopMode == MusicPlayLoopModeMax ? MusicPlayLoopModeMin : (MusicPlayLoopMode)((NSInteger)self.loopMode + 1));
}

- (void)playBackCompleted
{
    switch (self.loopMode) {
            
            //列表循环
        case MusicPlayLoopModeList:
        {
            [self next];
        }
            break;
            //单曲循环,默认
        case MusicPlayLoopModeOne:
        {
            [self playAtIndex:self.playingIndex];
        }
            break;
            
        default:
            break;
    }
    
    if ([self.delegate respondsToSelector:@selector(musicManagerDidFinishPlaying:)]) {
        [self.delegate musicManagerDidFinishPlaying:self];
    }
}

#pragma mark - 扬声器播放

- (void)playOutside
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //默认情况下扬声器播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
}


#pragma mark - 其他事件

///清除内存中所有播放信息
- (void)clearAllInfoWhenLogout
{
    [self stop];
    
    //播放列表
    self.playList = nil;
    //播放时间观察器
    [self.timer invalidate];
    //删除时间
    self.timer = nil;
    //正在播放的下标
    self.playingIndex = 0;
    //专辑图片
    self.albumImage = nil;
    //专辑图片url
    self.albumImageURL = nil;
    //专辑标题
    self.albumTitle = nil;
    //转换的播放列表
    self.itemList = nil;
}

//读取本地歌单
- (void)readListFormLocalDisk
{
    if (self.playList.count > 0)
    {
        return;
    }
    ///读取本地表单
    NSString *listStr = [JKMusicFileStorageManager readListFromFile];
    if (listStr.length > 0) {
        NSError *err = nil;
        JKMusicListData *data = [[JKMusicListData alloc] initWithString:listStr usingEncoding:NSUTF8StringEncoding error:&err];
        if (err) {
            NSLog(@"local music list jsonmodel error : %@",err);
        }else{
            [self addMusicItemListDataInMainMode:data];
            [self playAndPause];
        }
    }
}


//当重试失败的时候，调用本地原声播放器
- (void)tryWhenRetryFailed
{
    //失败后停止第三方播放器
    [self.audioController stop];
    
    NSLog(@"------ FSAudio Player Failed,convert Native Audio Player ------");
    
    JKMusicListDataItem *item =  [self.playList safeObjectAtIndex:self.playingIndex];
    self.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:[item url]]];
    
    [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.player play];
    [self beginPlaying];
}

//移除原生播放器
- (void)removeNativePlayer
{
    if (!self.player) {
        return;
    }
    NSLog(@"--- Native Audio Player Destory! ---");
    [self.player removeObserver:self forKeyPath:@"rate" context:nil];
    self.player = nil;
    
}

- (void)doNothing
{
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"rate"]) {
        [self postNotificationStateChange];
    }
}

#pragma mark - 自定义代理

- (void)playProgessChange:(CGFloat)progress
{
    if ([self.delegate respondsToSelector:@selector(musicManager:playingMusicInProgress:)]) {
        [self.delegate musicManager:self playingMusicInProgress:progress];
    }
}

- (void)bufferingProgressChange:(CGFloat)progress
{
    if ([self.delegate respondsToSelector:@selector(musicManager:bufferingMusicInProgress:)]) {
        [self.delegate musicManager:self bufferingMusicInProgress:progress];
    }
}

- (void)updateAlbumImage
{
    if ([self.delegate respondsToSelector:@selector(musicManager:upDateAlbumImage:)]) {
        [self.delegate musicManager:self upDateAlbumImage:self.albumImage];
    }
}

- (void)beginPlaying
{
    if ([self.delegate respondsToSelector:@selector(musicManagerBeginPlaying:)]) {
        [self.delegate musicManagerBeginPlaying:self];
    }
}

- (void)stopPlaying
{
    if ([self.delegate respondsToSelector:@selector(musicManagerStopPlaying:)]) {
        [self.delegate musicManagerStopPlaying:self];
    }
}

#pragma mark - 懒加载

- (NSMutableArray *)playList
{
    if (!_playList) {
        _playList = [NSMutableArray array];
    }
    return _playList;
}

- (FSStreamConfiguration *)configuration
{
    if (!_configuration) {
        _configuration = [[FSStreamConfiguration alloc] init];
        //缓存
        _configuration.cacheEnabled = YES;
        //缓存目录
        _configuration.cacheDirectory = [JKMusicFileStorageManager musicCachePath];
        _configuration.seekingFromCacheEnabled = YES;
        _configuration.requireStrictContentTypeChecking = NO;
        _configuration.usePrebufferSizeCalculationInSeconds = NO;
        _configuration.requiredInitialPrebufferedByteCountForContinuousStream = 100000;
        _configuration.requiredInitialPrebufferedByteCountForNonContinuousStream = 100000;
        //缓冲歌曲最大容量
        _configuration.maxPrebufferedByteCount = 10000000;//10 MB
        //本地缓存最大容量
        _configuration.maxDiskCacheSize = 128000000;//128 MB
    }
    return _configuration;
}

- (FSAudioController *)audioController
{
    if (!_audioController) {
        _audioController = [[FSAudioController alloc] init];
        _audioController.delegate = self;
        _audioController.configuration = self.configuration;
    }
    return _audioController;
}

- (NSMutableArray<FSPlaylistItem *> *)itemList
{
    if (!_itemList) {
        _itemList = [[NSMutableArray alloc] init];
    }
    return _itemList;
}

- (void)setDelegate:(id<JKMusicManagerDelegate>)delegate
{
    _delegate = delegate;
    
    if(self.playList.count <= 0)
    {
        [self readListFormLocalDisk];
    }
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self
                                                    selector:@selector(updatePlaybackProgress)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

- (Reachability *)reachNet
{
    if (!_reachNet) {
        _reachNet = [Reachability reachabilityForInternetConnection];
    }
    return _reachNet;
}


#pragma mark - 系统通知

- (void)postNotificationStateChange
{
    if(self.playList.count > 0){
        self.totalTime = [[self.playList safeObjectAtIndex:self.playingIndex] song_time];
    }
    
    [self updateScreenMusicInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:JKMusicPlayerStateChangeNotification object:nil];
}

///添加系统通知监听
- (void)addNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(ReachabilityChange) name:kReachabilityChangedNotification object:nil];
    [self.reachNet startNotifier];
    [center addObserver:self selector:@selector(pause) name:JKMoviePlayerDidBeginPlayNotification object:nil];
    [center addObserver:self selector:@selector(closeNaviteMusicNotification:) name:JKStopNaviteMusicNotification object:nil];
    [center addObserver:self selector:@selector(musicEventNotification:) name:JKMusicEventNotification object:nil];
    [center addObserver:self selector:@selector(postNotificationStateChange) name:UIApplicationDidBecomeActiveNotification object:nil];
}

///移除通知监听
- (void)dealloc
{
    [self removeNativePlayer];
    [self.reachNet stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 初始化

- (void)initializePlayerController
{
    self.audioController.preloadNextPlaylistItemAutomatically = NO;
    
    __weak typeof(self) weakSelf = self;
    
    self.audioController.onStateChange = ^(FSAudioStreamState state){
        
        switch (state) {
            case kFsAudioStreamRetrievingURL:
            {
                NSLog(@"music manager 正在解析url...");
                break;
            }
            case kFsAudioStreamFailed:
            {
                NSLog(@"music manager 失败");
                [weakSelf stop];
                //                        weakSelf.retryCount ++;
                //                        if (weakSelf.retryCount >= 3) {
                //                            [weakSelf tryWhenRetryFailed];
                //                        }else{
                //                            [weakSelf playAtIndex:weakSelf.playingIndex];
                //                        }
                break;
            }
            case kFsAudioStreamPaused:
            {
                NSLog(@"music manager 暂停");
                [weakSelf postNotificationStateChange];
                weakSelf.ajustPause = YES;
                break;
            }
            case kFsAudioStreamPlaying:
            {
                NSLog(@"music manager 播放中");
                weakSelf.stopped = NO;
                weakSelf.playLevel ++;
                if (weakSelf.cancelPlay&&!weakSelf.localCached) {
                    weakSelf.ajustPlayBtn = YES;
                    weakSelf.cancelPlay = NO;
                    NSLog(@"ajust playing break");
                    break;
                }
                weakSelf.ajustPause = NO;
                weakSelf.ajustPlayBtn = NO;
                [weakSelf beginPlaying];
                [weakSelf postNotificationStateChange];
                if (weakSelf.needSeekProgress) {
                    [weakSelf seekTimeWithProgress:weakSelf.aimProgress];
                    weakSelf.needSeekProgress = NO;
                }
                break;
            }
            case kFsAudioStreamSeeking:
            {
                NSLog(@"music manager 滑动进度条ing");
                break;
            }
            case kFsAudioStreamStopped:
            {
                NSLog(@"music manager 停止");
                weakSelf.stopped = YES;
                if (weakSelf.playLevel < 2) {
                    [weakSelf stopPlaying];
                }
                weakSelf.playLevel = 0;
                [weakSelf postNotificationStateChange];
                weakSelf.cancelPlay = NO;
                break;
            }
            case kFsAudioStreamBuffering:
            {
                NSLog(@"music manager 正在缓冲...");
                weakSelf.playLevel ++;
                break;
            }
            case kFSAudioStreamEndOfFile:
            {
                NSLog(@"music manager 缓冲完成");
                weakSelf.playLevel ++;
                if (weakSelf.changeModeFlag) {
                    weakSelf.changeModeFlag = NO;
                    break;
                }
                weakSelf.cancelPlay = YES;
                break;
            }
            case kFsAudioStreamUnknownState:
            {
                NSLog(@"music manager 未知状态");
                break;
            }
            case kFsAudioStreamRetryingFailed:
            {
                NSLog(@"music manager 重试失败");
                [weakSelf tryWhenRetryFailed];
                break;
            }
            case kFsAudioStreamRetryingStarted:
            {
                NSLog(@"music manager 开始重试");
                break;
            }
            case kFsAudioStreamPlaybackCompleted:
            {
                NSLog(@"music manager 播放完成");
                [weakSelf playBackCompleted];
                [weakSelf postNotificationStateChange];
                break;
            }
            case kFsAudioStreamRetryingSucceeded:
            {
                NSLog(@"music manager 重试成功");
                break;
            }
                
            default:
                break;
        }
        //        if (weakSelf.retryCount >= 3) {
        //            [weakSelf tryWhenRetryFailed];
        //        }
    };
    
    weakSelf.audioController.onFailure = ^(FSAudioStreamError errorType, NSString *message) {
        NSString *errorCategory;
        
        switch (errorType) {
            case kFsAudioStreamErrorOpen:
                errorCategory = @"FStreamer Audio Player Cannot open the audio stream: ";
                break;
            case kFsAudioStreamErrorStreamParse:
                errorCategory = @"FStreamer Audio Player Cannot read the audio stream: ";
                break;
            case kFsAudioStreamErrorNetwork:
                errorCategory = @"FStreamer Audio Player Network failed: cannot play the audio stream: ";
                break;
            case kFsAudioStreamErrorUnsupportedFormat:
                errorCategory = @"FStreamer Audio Player Unsupported format: ";
                break;
            case kFsAudioStreamErrorStreamBouncing:
                errorCategory = @"FStreamer Audio Player Network failed: cannot get enough data to play: ";
                break;
            default:
                errorCategory = @"FStreamer Audio Player Unknown error occurred: ";
                break;
        }
        
        NSString *formattedError = [NSString stringWithFormat:@"%@ %@", errorCategory, message];
        
        NSLog(@"%@",formattedError);
    };
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(updatePlaybackProgress)
                                                userInfo:nil
                                                 repeats:YES];
    
    //记录当前网络状态
    self.netType = [self.reachNet currentReachabilityStatus];
    //设置默认循环模式
    _loopMode = MusicPlayLoopModeList;
    
    [self addNotificationObserver];
}

///重置标志位。。。
- (void)resetStatusFlag
{
    self.playLevel = 0;
    self.cancelPlay = NO;
    self.ajustPlayBtn = NO;
    self.ajustPause = NO;
}

#pragma mark - 网络环境变化

- (void)ReachabilityChange
{
    NSLog(@"music player network connect change !");
    
    NetworkStatus type = [self.reachNet currentReachabilityStatus];
    
    BOOL wifiToNoWifi = (self.netType == ReachableViaWiFi) && (type == ReachableViaWWAN);
    
    NSLog(@"previous network status %ld , current network status %ld",(long)self.netType,(long)type);
    
    self.netType = type;
    
    //播放器没有工作，不提示
    if (![self isPlaying]) {
        return;
    }
    
    //网络环境为wifi更改到非wifi，不提示
    if (!wifiToNoWifi) {
        return;
    }
    
    self.ajustPlayBtn = NO;
    [self stop];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"网络环境切换" message:nil delegate:self cancelButtonTitle:@"好" otherButtonTitles:nil];
    [alert show];
    
    self.localCached = [JKMusicFileStorageManager checkMusicCachedFileIntegrityWith:[self.playList safeObjectAtIndex:self.playingIndex]];
}


#pragma mark - 单例

+ (instancetype)defaultManager
{
    return [[[self class] alloc] init];
}

- (instancetype)init {
    static id obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ((obj = [super init])) {
            // 初始化
            NSLog(@"music manager initialize!");
            
            [self initializePlayerController];
            
        }
    });
    return obj;
}

- (id)copyWithZone:(NSZone *)zone{
    return self;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

- (void)closeNaviteMusicNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self isPlaying])
        {
            [self playAndPause];
        }
    });
}

#pragma mark - 锁屏音乐控制

- (void)musicEventNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    kJKMusicPlayState type = (kJKMusicPlayState)[userInfo[@"musicEventType"] integerValue];
    switch (type)
    {
        case kJKMusicPlayStatePlay:
        {
            if (![self isPlaying])
            {
                [self playAndPause];
            }
            break;
        }
        case kJKMusicPlayStateStop:
        case kJKMusicPlayStatePause:
        {
            if ([self isPlaying])
            {
                [self playAndPause];
            }
            break;
        }
        case kJKMusicPlayStatePrevious:
        {
            [self previous];
            [self updateScreenMusicInfo];
            break;
        }
        case kJKMusicPlayStateNext:
        {
            [self next];
            [self updateScreenMusicInfo];
            break;
        }
            
        default:
            break;
    }
}

- (void)updateScreenMusicInfo
{
    JKMusicListDataItem *item = [self obtainCurrentMainMusicItem];
    if (!item) {
        return;
    }
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    NSString *musicName = item.name;
    NSString *album = self.albumTitle;
    
    if (musicName.length > 0)
    {
        [songInfo setObject:musicName forKey:MPMediaItemPropertyTitle];
    }
    if (album.length > 0)
    {
        [songInfo setObject:album forKey:MPMediaItemPropertyAlbumTitle];
    }
    else
    {   //默认
        [songInfo setObject:@"音乐播放器" forKey:MPMediaItemPropertyAlbumTitle];
    }
    
    if (item.song_time.integerValue > 0)
    {
        [songInfo setObject:item.song_time forKey: MPMediaItemPropertyPlaybackDuration];
        int elapsedTime = self.player ? CMTimeGetSeconds(self.player.currentTime) : self.audioController.activeStream.currentTimePlayed.playbackTimeInSeconds;
        if (elapsedTime > 0)
        {
            [songInfo setObject:@(elapsedTime) forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime];
        }
    }
    
    if ([songInfo count] > 0)
    {
        UIImage *newImage = self.albumImage;
        if (!newImage)
        {
            newImage = [UIImage imageNamed:@"musicPlayer_albumDefaultImage.png"];
        }
        [songInfo setObject:[[MPMediaItemArtwork alloc] initWithImage:newImage] forKey:MPMediaItemPropertyArtwork];
        
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
    }
    
}


@end
