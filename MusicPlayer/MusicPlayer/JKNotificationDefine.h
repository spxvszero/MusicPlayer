//
//  JKNotificationDefine.h
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#ifndef JKNotificationDefine_h
#define JKNotificationDefine_h


#define JKMusicPlayerStateChangeNotification @"JKMusicPlayerStateChangeNotification"
#define JKMoviePlayerDidBeginPlayNotification @"JKMoviePlayerDidBeginPlayNotification"
#define JKStopNaviteMusicNotification @"JKStopNaviteMusicNotification"
#define JKMusicEventNotification @"JKMusicEventNotification"


///音乐播放事件
typedef NS_ENUM(NSInteger, kJKMusicPlayState)
{
    kJKMusicPlayStateNone = 100,
    kJKMusicPlayStatePlay = 101,
    kJKMusicPlayStateStop = 102,
    kJKMusicPlayStatePause = 103,
    kJKMusicPlayStatePrevious = 104,
    kJKMusicPlayStateNext = 105,
};

#endif /* JKNotificationDefine_h */
