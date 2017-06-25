//
//  JKMusicPlayerViewController.m
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import "JKMusicPlayerViewController.h"
#import "JKMusicScrollView.h"
#import "JKMusicSlider.h"
#import "JKMusicManager.h"
#import "JKMusicFileStorageManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+JK.h"
#import "JKNotificationDefine.h"


#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height
#define navigationBarHeight 44
#define statusBarHeight 20

@interface JKMusicPlayerViewController ()<JKMusicManagerDelegate,JKMusicScrollViewDelegate>

//背景模糊图
@property(nonatomic,strong) UIImageView *backImageView;
//专辑图
@property(nonatomic,strong) UIImage *albumImage;
//背景半透明遮罩
@property(nonatomic,strong) UIView *shadeView;
//专辑封面页
@property(nonatomic,strong) JKMusicScrollView *scrollView;
//播放按钮
@property(nonatomic,strong) UIButton *playBtn;
//下一首
@property(nonatomic,strong) UIButton *nextBtn;
//上一首
@property(nonatomic,strong) UIButton *previousBtn;
//循环按钮
@property(nonatomic,strong) UIButton *loopBtn;
//推送按钮
@property(nonatomic,strong) UIButton *pushBtn;
//进度条
@property(nonatomic,strong) JKMusicSlider *slider;
//返回按钮
@property(nonatomic,strong) UIButton *backButton;
//标题
@property(nonatomic,strong) UILabel *titleLabel;
//当前时间
@property(nonatomic,strong) UILabel *currentTimeLabel;
//总时间
@property(nonatomic,strong) UILabel *totalTimeLabel;
//添加歌单按钮
@property(nonatomic,strong) UIButton *addListBtn;
//分享按钮
@property(nonatomic,strong) UIButton *sharedBtn;
//音量调节
@property(nonatomic, strong) MPMusicPlayerController *volumn;
//音量手势
@property(nonatomic, strong) UIPanGestureRecognizer *volumnGesture;
@property(nonatomic, assign) CGPoint volumnBeginPoint;
@property(nonatomic, assign) BOOL volumnCanChange;
@property(nonatomic, assign) CGFloat beginVolumn;
@property(nonatomic, assign) CFTimeInterval beginTime;


//用户收藏歌单控制器
@property(nonatomic,strong) JKMusicPlayerViewController *listVC;
//用户收藏歌单
@property(nonatomic,strong) UIView *listView;
//歌单遮罩层
@property(nonatomic,strong) UIView *shadowView;

//音乐播放管理器
@property(nonatomic,strong) JKMusicManager *manager;


//用户正在操作导航条
@property(nonatomic,assign) BOOL isOnControl;
//纪录当前播放的总时间
@property(nonatomic,assign) CGFloat currentTotalTime;


@property(nonatomic,strong) NSMutableDictionary *recordDic;


@end

@implementation JKMusicPlayerViewController
#pragma mark - 生命周期

- (void)dealloc
{
    NSLog(@"music view controller has been dealloc !");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#if DEBUG
    
    self.volumn = [MPMusicPlayerController applicationMusicPlayer];
    self.volumnGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(systemVolumnChange:)];
    [self.view addGestureRecognizer:self.volumnGesture];
    
#endif
    
    [self.manager doNothing];
    
    [self setupSubviews];
    [self layoutSubviews];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.navigationController.navigationBar.alpha = 0;
    } completion:^(BOOL finished) {
        self.navigationController.navigationBar.hidden = YES;
    }];

    self.backButton.bounds = CGRectMake(0, 0, 50, 40);
    self.backButton.center = CGPointMake(9.f + 25.f, statusBarHeight + navigationBarHeight * 0.5);
    
        self.manager.delegate = self;
        self.totalTimeLabel.text = [self changeTimeSecondToMinuteString:[self.manager obtainTotalTime]];
    
    [self senderChangeState:self.playBtn];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    self.navigationController.navigationBar.hidden = NO;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.navigationController.navigationBar.alpha = 1;
    }];
    
}

- (void)dismiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 布局

- (UIRectEdge)edgesForExtendedLayout
{
    return UIRectEdgeAll;
}


- (void)setupSubviews
{
    [self.view addSubview:self.backImageView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.playBtn];
    [self.view addSubview:self.nextBtn];
    [self.view addSubview:self.loopBtn];
    [self.view addSubview:self.pushBtn];
    [self.view addSubview:self.previousBtn];
    [self.view addSubview:self.addListBtn];
    [self.view addSubview:self.sharedBtn];
    [self.view addSubview:self.slider];
    [self.view addSubview:self.currentTimeLabel];
    [self.view addSubview:self.totalTimeLabel];
}

- (void)layoutSubviews
{
    self.backImageView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
    self.shadeView.frame = self.backImageView.frame;
    
    [self.playBtn sizeToFit];
    [self.nextBtn sizeToFit];
    [self.previousBtn sizeToFit];
    [self.loopBtn sizeToFit];
    [self.pushBtn sizeToFit];
    self.nextBtn.bounds = CGRectInset(self.nextBtn.bounds, -10.f, -5.f);
    self.previousBtn.bounds = CGRectInset(self.previousBtn.bounds, -10.f, -5.f);
    self.loopBtn.bounds = CGRectInset(self.loopBtn.bounds, -10.f, -5.f);
    self.pushBtn.bounds = CGRectInset(self.pushBtn.bounds, -10.f, -5.f);
    
    self.slider.bounds = CGRectMake(0, 0, screenWidth, 10);
    
    CGFloat centerY = self.view.frame.size.height - 41.f;
    CGFloat centerX = self.view.center.x;
    //与播放按钮之间的间隔
    CGFloat playButtonGap = 48.f / 640.f * screenWidth;
    //与上一曲和下一曲之间的间隔，用于推送按钮和循环按钮
    CGFloat nextpreBtnGap = 66.f / 640.f * screenWidth;
    
    self.playBtn.center = CGPointMake(centerX, centerY);
    self.nextBtn.center = CGPointMake(centerX + playButtonGap + (self.playBtn.bounds.size.width + self.nextBtn.bounds.size.width) * 0.5, centerY);
    self.previousBtn.center = CGPointMake(centerX - playButtonGap - (self.playBtn.bounds.size.width + self.previousBtn.bounds.size.width) * 0.5, centerY);
    self.loopBtn.center = CGPointMake(CGRectGetMinX(self.previousBtn.frame) - nextpreBtnGap - self.loopBtn.bounds.size.width * 0.5, centerY);
    self.pushBtn.center = CGPointMake(CGRectGetMaxX(self.nextBtn.frame) + nextpreBtnGap + self.pushBtn.bounds.size.width * 0.5, centerY);
    self.slider.center = CGPointMake(centerX, centerY - 60);
    
    [self.titleLabel sizeToFit];
    self.titleLabel.center = CGPointMake(centerX, statusBarHeight + navigationBarHeight * 0.5);
    
    self.currentTimeLabel.frame = CGRectMake(11, CGRectGetMaxY(self.slider.frame) + 12, 50, 20);
    self.totalTimeLabel.frame = CGRectMake(screenWidth - 50 -11, CGRectGetMaxY(self.slider.frame)+ 12, 50, 20);
    
    self.scrollView.frame = CGRectMake(0, navigationBarHeight + statusBarHeight, screenWidth, CGRectGetMinY(self.slider.frame) - 25 - navigationBarHeight - statusBarHeight);
    
    CGFloat upBtnCenterY = CGRectGetMaxY(self.scrollView.frame) - 5.f;
    [self.addListBtn sizeToFit];
    [self.sharedBtn sizeToFit];
    self.addListBtn.bounds = CGRectInset(self.addListBtn.bounds, -10.f, -5.f);
    self.sharedBtn.bounds = CGRectInset(self.sharedBtn.bounds, -10.f, -5.f);
    self.addListBtn.center = CGPointMake(10.f + self.addListBtn.bounds.size.width * 0.5, upBtnCenterY);
    self.sharedBtn.center = CGPointMake(screenWidth - self.sharedBtn.bounds.size.width * 0.5 - 10.f, upBtnCenterY);
    
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


#pragma mark - 响应事件

- (void)systemVolumnChange:(UIPanGestureRecognizer *)gesture
{
    CGPoint locate = [gesture locationInView:self.scrollView];
    
    if (self.scrollView.pageIndex == 1 && locate.y > 0) {
        
        if (gesture.state == UIGestureRecognizerStateBegan) {
            self.volumnBeginPoint = locate;
            self.volumnCanChange = YES;
            self.beginVolumn = self.volumn.volume;
            self.beginTime = CFAbsoluteTimeGetCurrent();
        }
        
        if (gesture.state == UIGestureRecognizerStateChanged && self.volumnCanChange) {
            CGFloat abs = (locate.x - self.volumnBeginPoint.x);
            if (((abs > 0)? abs : -abs) <= 20) {
                CGFloat changeY = (locate.y - self.volumnBeginPoint.y)/10.f;
                self.volumn.volume = self.beginVolumn - (changeY/25.f);
            }
        }
        
        if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed) {
            self.volumnCanChange = NO;
            self.volumnBeginPoint = CGPointZero;
        }
        
    }else{
        self.volumnCanChange = NO;
        self.volumnBeginPoint = CGPointZero;
    }
    
    NSLog(@"timeInterval ----- %f",CFAbsoluteTimeGetCurrent() - self.beginTime);
    
    if ((self.volumn.volume - self.beginVolumn) > 0.3 && (CFAbsoluteTimeGetCurrent() - self.beginTime) < 0.5f) {
        self.volumnCanChange = NO;
        self.volumnBeginPoint = CGPointZero;
    }
}

//播放按钮点击事件
- (void)playButtonClick:(UIButton *)sender
{
    //注：这两个顺序不能变，否则烦死你
    [self.manager playAndPause];
    [self senderChangeState:sender];
}

//下一首按钮点击事件
- (void)nextButtonClick:(UIButton *)sender
{
    [self.manager next];
    self.scrollView.playingIndex = [self.manager obtainCurrentMainPlayingIndex];
}

//上一首按钮点击事件
- (void)previousButtonClick:(UIButton *)sender
{
    [self.manager previous];
    self.scrollView.playingIndex = [self.manager obtainCurrentMainPlayingIndex];
}

//添加歌单点击事件
- (void)addListBtnClick:(UIButton *)sender
{
//    [self showMusicList];
}

//分享点击事件
- (void)sharedBtnClick:(UIButton *)sender
{
    NSLog(@"shareButtonClicked");
}

- (void)loopBtnDidClick:(UIButton *)sender
{
    [self.manager changeLoopMode];
    
    [self loopModeChangeState:sender];
}

//滑动条
- (void)sliderDidTouch:(UISlider *)sender
{
    self.isOnControl = YES;
}

- (void)sliderDidValueChange:(UISlider *)sender
{
    self.currentTimeLabel.text = [self changeTimeSecondToMinuteString:self.currentTotalTime * sender.value/(sender.maximumValue - sender.minimumValue)];
}

- (void)sliderDidFinish:(UISlider *)sender
{
    self.isOnControl = NO;
    [self.manager seekTimeWithProgress:sender.value];
}

- (void)sliderDidCancel:(UISlider *)sender
{
    self.isOnControl = NO;
}



///播放状态UI改变
- (void)senderChangeState:(UIButton *)sender
{
    if ([self.manager isPlaying]) {
        [sender setBackgroundImage:[UIImage imageNamed:@"musicPlayer_pause.png"] forState:UIControlStateNormal];
        [sender setBackgroundImage:[UIImage imageNamed:@"musicPlayer_pause_highlighted.png"] forState:UIControlStateHighlighted];
    }else{
        [sender setBackgroundImage:[UIImage imageNamed:@"musicPlayer_play.png"] forState:UIControlStateNormal];
        [sender setBackgroundImage:[UIImage imageNamed:@"musicPlayer_play_highlighted.png"] forState:UIControlStateHighlighted];
    }
}


///循环模式UI改变
- (void)loopModeChangeState:(UIButton *)sender
{
    switch (self.manager.loopMode) {
        case MusicPlayLoopModeOne:
        {
            [sender setImage:[UIImage imageNamed:@"musicPlayer_loop.png"] forState:UIControlStateNormal];
        }
            break;
        case MusicPlayLoopModeList:
        {
            [sender setImage:[UIImage imageNamed:@"musicPlayer_listLoop.png"] forState:UIControlStateNormal];
        }
            break;
            
        default:
            break;
    }
}


#pragma mark - 用户收藏歌单界面

- (void)showMusicList
{
    self.shadowView = [[UIView alloc] initWithFrame:self.view.frame];
    self.shadowView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    [self.shadowView addSubview:self.listView];
    [self.view addSubview:self.shadowView];
    //为它设置点击事件
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMusicList)];
    [self.shadowView addGestureRecognizer:tap];
    
//    self.listVC.musicIndex = [self.manager obtainCurrentMainPlayingIndex];
    self.shadowView.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.shadowView.alpha = 1;
    } completion:^(BOOL finished) {
        self.listView.alpha = 1;
    }];
}

- (void)dismissMusicList
{
    [UIView animateWithDuration:0.25 animations:^{
        self.shadowView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.shadowView removeFromSuperview];
        self.shadeView = nil;
        self.listView = nil;
    }];
}

- (void)musicListViewControllerShouldDismiss
{
    [self dismissMusicList];
}

#pragma mark - 音乐播放器代理

- (void)musicManager:(JKMusicManager *)manager playingMusicInProgress:(CGFloat)progress
{
    if (self.isOnControl) {
        return;
    }
    
    ///进度条
    self.slider.value = 1.f / (self.slider.maximumValue - self.slider.minimumValue) * progress;
    
    ///时间
    self.totalTimeLabel.text = [self changeTimeSecondToMinuteString:[self.manager obtainTotalTime]];
    self.currentTimeLabel.text = [self changeTimeSecondToMinuteString:[self.manager obtainTotalTime] * progress];
}

- (void)musicManager:(JKMusicManager *)manager bufferingMusicInProgress:(CGFloat)progress
{
    self.slider.buffering = progress;
    
}

- (void)musicManager:(JKMusicManager *)manager upDateAlbumImage:(UIImage *)image
{
    self.backImageView.image = [image blurredImageWithRadius:8 iterations:2 tintColor:[UIColor clearColor]];
    self.scrollView.albumImage = image;
}

- (void)musicManagerBeginPlaying:(JKMusicManager *)manager
{
    NSLog(@"music play controller play button enable = YES");
    self.playBtn.enabled = YES;
    [self.playBtn setBackgroundImage:[UIImage imageNamed:@"musicPlayer_pause.png"] forState:UIControlStateNormal];
    [self.playBtn setBackgroundImage:[UIImage imageNamed:@"musicPlayer_pause_highlighted.png"] forState:UIControlStateHighlighted];
}

- (void)musicManagerStopPlaying:(JKMusicManager *)manager
{
    NSLog(@"music play controller play button enable = NO");
    self.playBtn.enabled = NO;
    [self.playBtn setBackgroundImage:[UIImage imageNamed:@"musicPlayer_play.png"] forState:UIControlStateNormal];
    [self.playBtn setBackgroundImage:[UIImage imageNamed:@"musicPlayer_play_highlighted.png"] forState:UIControlStateHighlighted];
    
}

- (void)musicManagerDidFinishPlaying:(JKMusicManager *)manager
{
    self.scrollView.playingIndex = [self.manager obtainCurrentMainPlayingIndex];
}


- (NSString *)changeTimeSecondToMinuteString:(CGFloat)timeSecond
{
    if (timeSecond < 0 || isnan(timeSecond)) {
        timeSecond = 0;
    }
    return [NSString stringWithFormat:@"%02d:%02d", (int)(timeSecond / 60.f), (int)timeSecond%60];
}

- (void)musicPlayStateChange
{
    self.scrollView.albumTitle = [self.manager obtainCurrentMainMusicItem].name;
    self.scrollView.playingIndex = [self.manager obtainCurrentMainPlayingIndex];
    [self senderChangeState:self.playBtn];
}


#pragma mark - 正在播放列表代理

- (void)musicList:(JKMusicScrollView *)scrollView didClickedAtIndex:(NSUInteger)index
{
    [self.manager playAtIndex:index];
}

- (void)musicList:(JKMusicScrollView *)scrollView dragScrollViewOffsetProgress:(CGFloat)progress
{
    self.addListBtn.alpha = 1 - progress;
    self.sharedBtn.alpha = 1 - progress;
}

#pragma mark - 懒加载

- (UIButton *)playBtn
{
    if (!_playBtn) {
        _playBtn = [[UIButton alloc] init];
        _playBtn.adjustsImageWhenDisabled = NO;
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"musicPlayer_play.png"] forState:UIControlStateNormal];
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"musicPlayer_play_highlighted.png"] forState:UIControlStateHighlighted];
        [_playBtn addTarget:self action:@selector(playButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIButton *)nextBtn
{
    if (!_nextBtn) {
        _nextBtn = [[UIButton alloc] init];
        [_nextBtn setImage:[UIImage imageNamed:@"musicPlayer_next.png"] forState:UIControlStateNormal];
        [_nextBtn setImage:[UIImage imageNamed:@"musicPlayer_next_highlighted.png"] forState:UIControlStateHighlighted];
        [_nextBtn addTarget:self action:@selector(nextButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        _nextBtn.enabled = [self.manager obtianCurrentMainPlayerList].count > 0;
    }
    return _nextBtn;
}

- (UIButton *)previousBtn
{
    if (!_previousBtn) {
        _previousBtn = [[UIButton alloc] init];
        [_previousBtn setImage:[UIImage imageNamed:@"musicPlayer_previous.png"] forState:UIControlStateNormal];
        [_previousBtn setImage:[UIImage imageNamed:@"musicPlayer_previous_highlighted.png"] forState:UIControlStateHighlighted];
        [_previousBtn addTarget:self action:@selector(previousButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        _previousBtn.enabled = [self.manager obtianCurrentMainPlayerList].count > 0;
    }
    return _previousBtn;
}

- (JKMusicSlider *)slider
{
    if (!_slider) {
        _slider = [[JKMusicSlider alloc] init];
        _slider.unbufferedColor = [UIColor colorWithWhite:1 alpha:0.5];
        _slider.bufferedColor = [UIColor colorWithWhite:1 alpha:0.8];
        _slider.readColor = [UIColor orangeColor];
        _slider.enabled = [self.manager obtianCurrentMainPlayerList].count > 0;
        if (self.recordDic) {
            _slider.value = 1.f / (self.slider.maximumValue - self.slider.minimumValue) * [self.recordDic[kRecordPlayProgress] doubleValue];
            _slider.buffering = [self.manager currentBuffering];
            ///时间
            self.totalTimeLabel.text = [self changeTimeSecondToMinuteString:[self.recordDic[kRecordPlayTotalTime] integerValue]];
            self.currentTimeLabel.text = [self changeTimeSecondToMinuteString:[self.recordDic[kRecordPlayTotalTime] integerValue] * [self.recordDic[kRecordPlayProgress] doubleValue]];
        }
        
        [_slider setThumbImage:[UIImage imageNamed:@"musicPlayer_sliderPoint.png"] forState:UIControlStateNormal];
        [_slider addTarget:self action:@selector(sliderDidTouch:) forControlEvents:UIControlEventTouchDown];
        [_slider addTarget:self action:@selector(sliderDidValueChange:) forControlEvents:UIControlEventValueChanged];
        [_slider addTarget:self action:@selector(sliderDidFinish:) forControlEvents:UIControlEventTouchUpInside];
        [_slider addTarget:self action:@selector(sliderDidCancel:) forControlEvents:UIControlEventTouchCancel|UIControlEventTouchUpOutside];
    }
    return _slider;
}

- (UIButton *)addListBtn
{
    if (!_addListBtn) {
        _addListBtn = [[UIButton alloc] init];
        [_addListBtn setImage:[UIImage imageNamed:@"musicPlayer_addList.png"] forState:UIControlStateNormal];
        [_addListBtn addTarget:self action:@selector(addListBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _addListBtn.enabled = [self.manager obtianCurrentMainPlayerList].count > 0;
    }
    return _addListBtn;
}

- (UIButton *)sharedBtn
{
    if (!_sharedBtn) {
        _sharedBtn = [[UIButton alloc] init];
        [_sharedBtn setImage:[UIImage imageNamed:@"musicPlayer_shared.png"] forState:UIControlStateNormal];
        [_sharedBtn addTarget:self action:@selector(sharedBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _sharedBtn.enabled = [self.manager obtianCurrentMainPlayerList].count > 0;
    }
    return _sharedBtn;
}

- (UIButton *)pushBtn
{
    if (!_pushBtn) {
        _pushBtn = [[UIButton alloc] init];
        [_pushBtn setImage:[UIImage imageNamed:@"musicPlayer_push.png"] forState:UIControlStateNormal];
        _pushBtn.enabled = [self.manager obtianCurrentMainPlayerList].count > 0;
    }
    return _pushBtn;
}

- (UIButton *)loopBtn
{
    if (!_loopBtn) {
        _loopBtn = [[UIButton alloc] init];
        switch (self.manager.loopMode) {
            case MusicPlayLoopModeOne:
            {
                [_loopBtn setImage:[UIImage imageNamed:@"musicPlayer_loop.png"] forState:UIControlStateNormal];
            }
                break;
            case MusicPlayLoopModeList:
            {
                [_loopBtn setImage:[UIImage imageNamed:@"musicPlayer_listLoop.png"] forState:UIControlStateNormal];
            }
                break;
                
            default:
                [_loopBtn setImage:[UIImage imageNamed:@"musicPlayer_listLoop.png"] forState:UIControlStateNormal];
                break;
        }
        [_loopBtn addTarget:self action:@selector(loopBtnDidClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _loopBtn;
}

- (JKMusicScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[JKMusicScrollView alloc] init];
        _scrollView.musicList = [self.manager obtianCurrentMainPlayerList];
        _scrollView.albumImage = [self.manager obtainAlbumImage]?:[UIImage imageNamed:@"musicPlayer_albumDefaultImage.png"];
        _scrollView.albumTitle = [self.manager obtainCurrentMainMusicItem].name;
        _scrollView.playingIndex = [self.manager obtainCurrentMainPlayingIndex];
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (UIButton *)backButton
{
    if (!_backButton) {
        _backButton = [[UIButton alloc] init];
        [_backButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [_backButton setImage:[UIImage imageNamed:@"navigationbar_back.png"] forState:UIControlStateNormal];
        _backButton.imageEdgeInsets = UIEdgeInsetsMake(0, - 15.f, 0, 0);
        [self.view addSubview:_backButton];
    }
    return _backButton;
}

- (UILabel *)totalTimeLabel
{
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc] init];
        _totalTimeLabel.font = [UIFont systemFontOfSize:13];
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.text = @"00:00";
        _totalTimeLabel.textAlignment = NSTextAlignmentRight;
    }
    return _totalTimeLabel;
}

- (UILabel *)currentTimeLabel
{
    if (!_currentTimeLabel) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.font = [UIFont systemFontOfSize:13];
        _currentTimeLabel.text = @"00:00";
        _currentTimeLabel.textColor = [UIColor whiteColor];
    }
    return _currentTimeLabel;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"歌曲播放";
        _titleLabel.textColor = [UIColor whiteColor];
    }
    return _titleLabel;
}

- (UIImageView *)backImageView
{
    if (!_backImageView) {
        _backImageView = [[UIImageView alloc] init];
        _backImageView.contentMode = UIViewContentModeScaleAspectFill;
        _backImageView.layer.masksToBounds = YES;
        _backImageView.image = [[self.manager obtainAlbumImage]?:[UIImage imageNamed:@"musicPlayer_albumDefaultImage.png"] blurredImageWithRadius:8 iterations:2 tintColor:[UIColor clearColor]];
        [_backImageView addSubview:self.shadeView];
    }
    return _backImageView;
}

- (UIView *)shadeView
{
    if (!_shadeView) {
        _shadeView = [[UIView alloc] init];
        _shadeView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    }
    return _shadeView;
}

//- (UIView *)listView
//{
//    if (!_listView) {
//        self.listVC = [[JKMusicListViewController alloc] init];
//        self.listVC.albumName = [self.manager obtainAlbumTitle];
//        self.listVC.musicIndex = [self.manager obtainCurrentMainPlayingIndex];
//        self.listVC.delegate = self;
//        //        [self addChildViewController:self.listVC];
//        _listView = self.listVC.view;
//        _listView.bounds = CGRectMake(0, 0, screenWidth - 2 * (101.f/640.f) * screenWidth, screenHeight - (290.f + 375.f)/1136.f * screenHeight);
//        _listView.center = CGPointMake(self.view.center.x, self.view.center.y - 20.f);
//        _listView.layer.cornerRadius = 2.5f;
//        _listView.layer.masksToBounds = YES;
//    }
//    return _listView;
//}

- (JKMusicManager *)manager
{
    if (!_manager) {
        _manager = [JKMusicManager defaultManager];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(musicPlayStateChange) name:JKMusicPlayerStateChangeNotification object:nil];
            _manager.delegate = self;
    }
    return _manager;
}

- (CGFloat)currentTotalTime
{
    if (_currentTotalTime <= 0  || isnan(_currentTotalTime) ) {
        _currentTotalTime = [self.manager obtainTotalTime];
    }
    return _currentTotalTime;
}


@end
