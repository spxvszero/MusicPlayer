# MusicPlayer 音乐播放器
这是我以前项目里写的音乐播放器，现在有空把它从项目里面剥离出来了，方便以后移植使用或者扩展吧    
本播放器基于*FreeStreamer*，具体可以查看<https://github.com/muhku/FreeStreamer>  
另外用到的库有SDWebImage、JSONModel等   
基本算是完整的一个播放器了，能够离线存储听过的音乐   
# 用法
非常简单，该播放器是个单例，放入data对象就能自动播放
<pre><code>
JKMusicListData *data = [[JKMusicListData alloc] initWithString:songData usingEncoding:NSUTF8StringEncoding error:&err];   
[[JKMusicManager defaultManager] addMusicItemListDataInMainMode:data];  
</code></pre>
其中，songData是传入的json歌单，具体格式是定义为
 <pre><code>
 json 数据格式如下  
 {   
	index:当前需要播放的歌曲  
	image:图片URL;  
	name:标题；   
	song_list:当前整个播放列表    
	[{   
		 _id:歌曲id;   
		 name:歌曲名称； 
		 filesize:歌曲文件大小；  
		 type:歌曲类别   
		 md5:歌曲MD5;   
		 url:歌曲URL;   
		 song_type:歌曲所在分类类别：‘album’,'station','topic','grow','ip'等等   
		 tagval:歌曲所在分类ID;   
	}]   
 }  
 </code></pre>  
 更具体的做法都在demo里面
 
 # 预览图
 ![image](https://github.com/spxvszero/MusicPlayer/blob/master/ScreenShot/1.jpg)
 ![image](https://github.com/spxvszero/MusicPlayer/blob/master/ScreenShot/2.jpg)  
