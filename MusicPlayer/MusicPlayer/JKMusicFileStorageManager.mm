//
//  JKMusicFileStorageManager.m
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import "JKMusicFileStorageManager.h"

#import "JKMusicListData.h"
#import "BaseFile.h"
#import "NSString+Hash.h"
#import "FileHash.h"

#define kMusicDir @"musicCache"   ///存放文件夹
#define kMusicListData @"listData"   ///存放的当前收听歌单列表
#define kMusicListDataPB @"likeListData"  ///存放用户收藏的歌单列表

@implementation JKMusicFileStorageManager
//音乐资源存储路径
+ (NSString *)musicCachePath;
{
    return [NSString stringWithFormat:@"%@/%@", NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject, kMusicDir];
}


///存储路径
+ (NSString*)getFilePath:(NSString*)fileName
{
    NSString* settingFolder = [NSString stringWithFormat:@"%@/%@", NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject, kMusicDir];
    if (![CBaseFile FileExist:settingFolder]) {
        [CBaseFile CreatePath:settingFolder];
    }
    
    NSString *path = [NSString stringWithFormat:@"%@/%@", settingFolder, fileName];
    NSLog(@"music %@ storage path:%@", fileName, path);
    return path;
}

///删除资源
+ (void)removeFileWithName:(NSString *)fileName
{
    NSString* filePath = [self getFilePath:fileName];
    [CBaseFile RemoveFile:filePath];
}

///存储音乐播放列表文件
+ (BOOL)writeListToFile:(NSString *)listData
{
    if (listData.length <= 0)
    {
        return NO;
    }
    [[self class] removeFileWithName:kMusicListData];
    
    NSError *err = nil;
    
    BOOL ret = [listData writeToFile:[self getFilePath:kMusicListData] atomically:YES encoding:NSUTF8StringEncoding error:&err];
    
    if (err) {
        NSLog(@"save music file %@ cause error : %@",kMusicListData,err);
        return NO;
    }
    return ret;
}

///获取音乐播放列表文件
+ (NSString *)readListFromFile
{
    NSError *err = nil;
    NSString *fileStr = [NSString stringWithContentsOfFile:[self getFilePath:kMusicListData] encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        NSLog(@"read music list file error : %@",err);
        return nil;
    }
    return fileStr;
}


+ (BOOL)tempListIfExist
{
    
    NSString *tempStr = [[self class] readListFromFile];
    NSError *err = nil;
    JKMusicListData *data = [[JKMusicListData alloc] initWithString:tempStr usingEncoding:NSUTF8StringEncoding error:&err];
    if (err) {
        NSLog(@"local music list jsonmodel error : %@",err);
        return NO;
    }
    
    if (!data) {
        NSLog(@"local music list is nil");
        return NO;
    }
    
    return YES;
}


#pragma mark - 检查资源完整性
/////查询本地资源完整性
+ (BOOL)checkMusicCachedFileIntegrityWith:(JKMusicListDataItem *)item
{
    NSString *localMD5 = [[self class] getCachedMD5WithURLStr:item.url];
    
    NSLog(@"current music cached md5 %@ ,net md5 %@",localMD5,item.md5);
    
    if (localMD5.length <= 0) {
        ///本地没有缓存文件，直接返回
        NSLog(@"no local cached!");
        return NO;
    }
    
    if ([localMD5 isEqualToString:item.md5]) {//md5相同
        NSLog(@"the same md5,use local cached");
        return YES;
    }else{
        
        ///md5不同，清除本地缓存
        [[self class] clearCacheWithURLStr:item.url];
        NSLog(@"remove local music cached !");
        return NO;
    }
}


////根据音乐下载链接删除本地缓存
+ (void)clearCacheWithURLStr:(NSString *)urlStr
{
    NSString *cacheFileName = [NSString stringWithFormat:@"FSCache-%@",[urlStr musicHashString]];
    
    NSString *cacheDir = [[self class] musicCachePath];
    
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheDir error:nil]) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", cacheDir, file];
        
        if ([file hasPrefix:cacheFileName]) {
            if (![[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil]) {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
                NSLog(@"Failed expunging %@ from the cache", fullPath);
#endif
            }
        }
    }
}

///获取缓存md5
+ (NSString *)getCachedMD5WithURLStr:(NSString *)urlStr;
{
    NSString *cacheFileName = [NSString stringWithFormat:@"FSCache-%@",[urlStr musicHashString]];
    
    NSString *fullPath = [[self class] getFilePath:cacheFileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        NSLog(@"music cache file is not exist,%@",cacheFileName);
        return nil;
    }
    
    return [FileHash md5HashOfFileAtPath:fullPath];
}

+ (void)clearAllMusicCache
{
    NSString *cacheDir = [[self class] musicCachePath];
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheDir error:nil]) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", cacheDir, file];
        
        if ([file hasPrefix:@"FSCache-"] || [file hasPrefix:kMusicListData]) {
            if (![[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil]) {
#if defined(DEBUG) || (TARGET_IPHONE_SIMULATOR)
                NSLog(@"Failed expunging %@ from the cache", fullPath);
#endif
            }
        }
    }
}


@end
