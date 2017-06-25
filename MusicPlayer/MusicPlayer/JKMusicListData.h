//
//  JKMusicListData.h
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import "JSONModel.h"

@protocol JKMusicListDataItem
@end

@interface JKMusicListDataItem : JSONModel

//歌曲id
@property(nonatomic,strong) NSString *_id;
//歌曲名字
@property(nonatomic,strong) NSString *name;
//歌曲文件大小
@property(nonatomic,strong) NSString *filesize;
//歌曲时间
@property(nonatomic,strong) NSString *song_time;
//歌曲类型
@property(nonatomic,strong) NSString *type;
//歌曲md5
@property(nonatomic,strong) NSString *md5;
//歌曲url
@property(nonatomic,strong) NSString *url;
//歌曲所在分类类别：‘album’,'station','topic','grow','ip'等等
@property(nonatomic,strong) NSString *song_type;
//歌曲的分类id。注：song_type决定好后，该字段表示这个类别里面的id
@property(nonatomic,strong) NSString *tagval;
//歌曲分享跳转url
@property(nonatomic,strong) NSString *link;

@end



@interface JKMusicListData : JSONModel

@property(nonatomic,assign) NSUInteger index;///当前播放的歌曲下标
@property(nonatomic,strong) NSString *name;///专辑名
@property(nonatomic,strong) NSString *image;
@property(nonatomic,strong) NSArray<JKMusicListDataItem> *song_list;


@end
