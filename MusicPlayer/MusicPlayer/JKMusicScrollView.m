//
//  JKMusicScrollView.m
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import "JKMusicScrollView.h"
#import "JKMusicListData.h"

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height

#define musicListIdentify @"musicList"
#define MainScrollViewTag 777

@interface JKMusicListCell ()

@property(nonatomic,strong) UIView *topLine;
@property(nonatomic,strong) UIView *bottomLine;

@property(nonatomic,strong) UILabel *musicLabel;
@property(nonatomic,strong) UIButton *musicImgView;
@property(nonatomic,strong) UIImageView *playImgView;

@end
@implementation JKMusicListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    self.topLine = [[UIView alloc] init];
    self.topLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    self.topLine.hidden = YES;
    [self addSubview:self.topLine];
    
    self.bottomLine = [[UIView alloc] init];
    self.bottomLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    [self addSubview:self.bottomLine];
    
    self.musicImgView = [[UIButton alloc] init];
    [self.musicImgView setImage:[UIImage imageNamed:@"musicPlayer_itemPlayingMelody_normal.png"] forState:UIControlStateNormal];
    [self.musicImgView setImage:[UIImage imageNamed:@"musicPlayer_itemPlayingMelody.png"] forState:UIControlStateSelected];
    [self addSubview:self.musicImgView];
    
    self.musicLabel = [[UILabel alloc] init];
    self.musicLabel.textColor = [UIColor whiteColor];
    self.musicLabel.font = [UIFont systemFontOfSize:14];
    [self addSubview:self.musicLabel];
    
    self.playImgView = [[UIImageView alloc] init];
    self.playImgView.image = [UIImage imageNamed:@"musicPlayer_itemPlaying.png"];
    self.playImgView.hidden = YES;
    [self addSubview:self.playImgView];
    
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if ([self isFirstCell]) {
        self.topLine.hidden = NO;
        self.topLine.frame = CGRectMake(0, 0, self.bounds.size.width, 0.5);
    }else{
        self.topLine.hidden = YES;
    }
    self.bottomLine.frame = CGRectMake(30 , self.bounds.size.height - 0.5, self.bounds.size.width - 30, 0.5);
    
    [self.musicImgView sizeToFit];
    self.musicImgView.center = CGPointMake(7 + self.musicImgView.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    
    [self.playImgView sizeToFit];
    self.playImgView.center = CGPointMake(self.bounds.size.width - 20 - 16, self.bounds.size.height * 0.5);
    
    [self.musicLabel sizeToFit];
    self.musicLabel.frame = CGRectMake(30.f, self.bounds.size.height * 0.5 - self.musicLabel.bounds.size.height * 0.5, CGRectGetMinX(self.playImgView.frame) - 40.f, self.musicLabel.bounds.size.height);
}

- (void)setMusicName:(NSString *)musicName
{
    _musicName = musicName;
    self.musicLabel.text = musicName;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (self.selected) {
        self.playImgView.hidden = NO;
        self.musicLabel.textColor = [UIColor redColor];
        self.musicImgView.selected = YES;
    }else{
        self.playImgView.hidden = YES;
        self.musicLabel.textColor = [UIColor whiteColor];
        self.musicImgView.selected = NO;
    }
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.backgroundColor = [UIColor clearColor];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self touchesCancelled:touches withEvent:event];
}

@end


@interface JKMusicScrollView ()<UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate>

//主页面的滚动视图
@property(nonatomic,strong) UIScrollView *scrollView;
//播放列表
@property(nonatomic,strong) UITableView *tableViewList;
//专辑页面
@property(nonatomic,strong) UIView *albumView;
//专辑页面里的图
@property(nonatomic,strong) UIImageView *albumImageView;
//专辑页面里的标题
@property(nonatomic,strong) UILabel *albumTitleLabel;
//专辑页面里的页面点
@property(nonatomic,strong) UIPageControl *pageControl;

@end
@implementation JKMusicScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    [self addSubview:self.scrollView];
    [self addSubview:self.pageControl];
    [self.scrollView addSubview:self.tableViewList];
    [self.scrollView addSubview:self.albumView];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    //图片距离两边的间隔
    CGFloat imgViewGap = 97.f/640.f * screenWidth;
    
    self.scrollView.frame = self.bounds;
    self.tableViewList.frame = CGRectMake(0, 0, screenWidth, self.scrollView.bounds.size.height - 16);
    self.albumView.frame = CGRectMake(screenWidth, 0, screenWidth, self.scrollView.bounds.size.height);
    if(screenHeight < 568){
        self.albumImageView.frame = CGRectMake(imgViewGap + 10.f, 0, screenWidth - 2 * imgViewGap - 20.f, screenWidth - 2 * imgViewGap - 20.f);
    }else{
        self.albumImageView.frame = CGRectMake(imgViewGap, imgViewGap, screenWidth - 2 * imgViewGap, screenWidth - 2 * imgViewGap);
    }
    self.albumTitleLabel.bounds = CGRectMake(0, 0, screenWidth - 40.f, 60);
    if (screenHeight < 568) {
        self.albumTitleLabel.center = CGPointMake(self.scrollView.center.x, CGRectGetMaxY(self.albumImageView.frame) + 5.f + self.albumTitleLabel.bounds.size.height * 0.5);
    }else{
        self.albumTitleLabel.center = CGPointMake(self.scrollView.center.x, CGRectGetMaxY(self.albumImageView.frame) + 52.f/1136.f * screenHeight + self.albumTitleLabel.bounds.size.height * 0.5);
    }
    self.scrollView.contentSize = CGSizeMake(2*screenWidth, 0);
    self.scrollView.contentOffset = CGPointMake(screenWidth, 0);
    
    self.pageControl.center = CGPointMake(self.center.x, self.bounds.size.height - 5);
}


#pragma mark - tableView代理

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.musicList.count > 0 ? self.musicList.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JKMusicListCell *cell = [tableView dequeueReusableCellWithIdentifier:musicListIdentify];
    
    if (!cell) {
        cell = [[JKMusicListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:musicListIdentify];
    }
    if (indexPath.row == 0){
        cell.firstCell = YES;
    }else{
        cell.firstCell = NO;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    
    JKMusicListDataItem *item = self.musicList[indexPath.row];
    
    cell.musicName = item.name;
    
    if (indexPath.row == self.playingIndex) {
        cell.selected = YES;
    }else{
        cell.selected = NO;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.playingIndex == indexPath.row) {
        return;
    }
    self.playingIndex = indexPath.row;
    
    if ([self.delegate respondsToSelector:@selector(musicList:didClickedAtIndex:)]) {
        [self.delegate musicList:self didClickedAtIndex:indexPath.row];
    }
}

#pragma mark - scrollView代理

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.tag == MainScrollViewTag) {
        self.pageControl.currentPage = scrollView.contentOffset.x > screenWidth * 0.5 ? 1 : 0;
        
        if ([self.delegate respondsToSelector:@selector(musicList:dragScrollViewOffsetProgress:)]) {
            [self.delegate musicList:self dragScrollViewOffsetProgress:(screenWidth - scrollView.contentOffset.x)/screenWidth];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.musicList.count <= 0) {
        return;
    }
    
    if (scrollView.tag == MainScrollViewTag) {
        if (scrollView.contentOffset.x == 0) {
            NSIndexPath *iP = [NSIndexPath indexPathForRow:self.playingIndex inSection:0];
            [self.tableViewList scrollToRowAtIndexPath:iP atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
}


#pragma mark - 懒加载

- (NSUInteger)pageIndex
{
    return self.pageControl.currentPage;
}

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delegate = self;
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.tag = MainScrollViewTag;
        
    }
    return _scrollView;
}

- (UIPageControl *)pageControl
{
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.numberOfPages = 2;
        _pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1 alpha:0.5];
        _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    }
    return _pageControl;
}

- (UITableView *)tableViewList
{
    if (!_tableViewList) {
        _tableViewList = [[UITableView alloc] init];
        _tableViewList.delegate = self;
        _tableViewList.dataSource = self;
        _tableViewList.backgroundColor = [UIColor clearColor];
        _tableViewList.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableViewList.allowsSelection = YES;
        _tableViewList.allowsMultipleSelection = NO;
        _tableViewList.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    }
    return _tableViewList;
}

- (UIView *)albumView
{
    if (!_albumView) {
        _albumView = [[UIView alloc] init];
        _albumView.backgroundColor = [UIColor clearColor];
        [_albumView addSubview:self.albumImageView];
        [_albumView addSubview:self.albumTitleLabel];
    }
    return _albumView;
}

- (UIImageView *)albumImageView
{
    if (!_albumImageView) {
        _albumImageView = [[UIImageView alloc] init];
        //        _albumImageView.image = [UIImage imageNamed:@"add_record@3x.png"];
        _albumImageView.layer.masksToBounds = YES;
        _albumImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _albumImageView;
}

- (UILabel *)albumTitleLabel
{
    if (!_albumTitleLabel) {
        _albumTitleLabel = [[UILabel alloc] init];
        _albumTitleLabel.textColor = [UIColor whiteColor];
        _albumTitleLabel.numberOfLines = 2;
        _albumTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _albumTitleLabel;
}

- (void)setAlbumTitle:(NSString *)albumTitle
{
    _albumTitle = albumTitle;
    
    self.albumTitleLabel.text = albumTitle;
}

- (void)setAlbumImage:(UIImage *)albumImage
{
    _albumImage = albumImage;
    
    self.albumImageView.image = albumImage;
}

- (void)setPlayingIndex:(NSInteger)playingIndex
{
    _playingIndex = playingIndex;
    
    [self.tableViewList reloadData];
}

@end
