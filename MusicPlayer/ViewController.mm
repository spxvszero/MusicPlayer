//
//  ViewController.m
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import "ViewController.h"
#import "JKMusicPlayerViewController.h"
#import "JKMusicListData.h"
#import "JKMusicFileStorageManager.h"
#import "JKMusicManager.h"

@interface ViewController ()

@property (nonatomic,strong) NSString *testDataString;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    self.testDataString = @"{\"index\":0,\"name\":\"月光\",\"image\":\"https:\/\/gss1.bdstatic.com\/9vo3dSag_xI4khGkpoWK1HF6hhy\/baike\/c0%3Dbaike80%2C5%2C5%2C80%2C26\/sign=2ef054847d3e6709aa0d4dad5aaef458\/63d9f2d3572c11df209a1780612762d0f603c2ce.jpg\",\"song_list\":[{\"song_type\":\"album\",\"md5\":\"8417b5de01819926c702896824b4def2\",\"filesize\":\"1020909\",\"_id\":\"39381\",\"tagval\":\"499\",\"link\":\"http:\/\/www.baiduc.com\",\"song_time\":\"0\",\"type\":\"0\",\"name\":\"月光进行曲\",\"url\":\"http:\/\/media.youban.com\/gsmp3\/mqualityt300\/1294393922533972933.mp3\"},{\"song_type\":\"album\",\"md5\":\"f01bcd9c7ae77a80af3c53e02f9b73a0\",\"filesize\":\"1020909\",\"_id\":\"221\",\"tagval\":\"19\",\"link\":\"http:\/\/www.baiduc.com\",\"song_time\":\"0\",\"type\":\"0\",\"name\":\"致爱丽丝\",\"url\":\"http:\/\/media.youban.com\/gsmp3\/mqualityt300\/12922277641892162125.mp3\"}]}";
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    
    [self playMuiscByApp:self.testDataString];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 json 数据格式如下
 {
	index:当前需要播放的歌曲
 image:图片URL;
 name:标题；
	song_list:当前整个播放列表
	{
 _id:歌曲id;
 name:歌曲名称；
 filesize:歌曲文件大小；
 type:歌曲类别
 md5:歌曲MD5;
 url:歌曲URL;
 song_type:歌曲所在分类类别：‘album’,'station','topic','grow','ip'等等
 tagval:歌曲所在分类ID;
	}
 }
 */
- (void)playMuiscByApp:(NSString *)songData
{
    if (songData.length > 0) {
        NSLog(@"H5 music list data : %@",songData);
        
        NSError *err = nil;
        JKMusicListData *data = [[JKMusicListData alloc] initWithString:songData usingEncoding:NSUTF8StringEncoding error:&err];
        
        if (err) {
            NSLog(@"H5 music list jsonmodel error : %@",err);
            return ;
        }
        
        
        static int mpFlag;
        
        
        if (mpFlag <= 0 ) {
            
            ///没有问题的话，写本地文件
            [JKMusicFileStorageManager writeListToFile:songData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[JKMusicManager defaultManager] addMusicItemListDataInMainMode:data];
                
                JKMusicPlayerViewController *mVC = [[JKMusicPlayerViewController alloc] init];
                
                [self.navigationController pushViewController:mVC animated:YES];
            });
        
        
        
            mpFlag = 1;
            return;
        }
        
        ///没有问题的话，写本地文件
        [JKMusicFileStorageManager writeListToFile:songData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[JKMusicManager defaultManager] addMusicItemListDataInMainMode:data];
            
            JKMusicPlayerViewController *mVC = [[JKMusicPlayerViewController alloc] init];
            
            [self.navigationController pushViewController:mVC animated:YES];
        });
    }
}


@end
