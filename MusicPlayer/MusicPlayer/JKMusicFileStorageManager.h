//
//  JKMusicFileStorageManager.h
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import <Foundation/Foundation.h>


@class JKMusicListDataItem;

@interface JKMusicFileStorageManager : NSObject

//音乐资源存储路径
+ (NSString *)musicCachePath;

//歌曲列表
+ (BOOL)writeListToFile:(NSString *)listData;
+ (NSString *)readListFromFile;
+ (BOOL)tempListIfExist;

///查询本地资源完整性，返回值表示本地有没有文件，不代表所做的操作
+ (BOOL)checkMusicCachedFileIntegrityWith:(JKMusicListDataItem *)item;

+ (void)clearAllMusicCache;


@end
