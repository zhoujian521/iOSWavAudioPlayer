//
//  ZJPlayer.h
//  Pods-ZJPlayer_Example
//
//  Created by BJQingniuJJ on 2017/12/11.
//
/**
   ZJPlayer 测试 Url
   http://101.200.216.120/g1/M00/5E/9F/Ciy1JFkmfKWAcRTVAACGnenYDYk007.mp3?fileName=6582334644715396302.mp3
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, ZJPlayerState){
    ZJPlayerStatusUnknown = 1,       //位置状态
    ZJPlayerStatusFailed,            //播放失败
    ZJPlayerStatusReadyToPlay,       //加载完成可以播放
    ZJPlayerStatusBuffering,         //正在缓存
    ZJPlayerStatusPlaying,           //正在播放
    ZJPlayerStatusStopped,           //暂停播放
};

typedef NS_ENUM (NSInteger, ZJPlayerResourceType){
    ZJPlayerResourceRemote = 1,     // 远程资源
    ZJPlayerResourceLocal,          // 本地资源
};

@class ZJPlayer;
@protocol ZJPlayerDelegate <NSObject>

-(void)audioPlayer:(ZJPlayer *)player playStateChanged:(ZJPlayerState)state;

@end

/**
 静音
 */
@interface ZJPlayer : NSObject

@property (nonatomic, assign) id<ZJPlayerDelegate> delegate;
//播放状态
@property (nonatomic, assign, readonly) ZJPlayerState playerState;
// 倍速
@property (nonatomic, assign) float rate;
// 静音控制
@property (nonatomic, assign) BOOL muted;
// 音量控制
@property (nonatomic, assign) float volume;

+ (instancetype)shareManager;
// 播放
- (void)playingWithResource:(ZJPlayerResourceType )resource url:(NSURL *)url isCache:(BOOL)isCache;
// 暂停
- (void)pause;
// 播放
- (void)resume;
// 停止
- (void)stop;
// 快进【x】s
- (void)seekWithTimeInterval:(NSTimeInterval)timeInterval;
//【x】倍速播放
- (void)seekToProgress:(float)progress;

@end
