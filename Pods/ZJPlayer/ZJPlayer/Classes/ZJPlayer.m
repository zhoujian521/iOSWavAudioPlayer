//
//  ZJPlayer.m
//  Pods-ZJPlayer_Example
//
//  Created by BJQingniuJJ on 2017/12/11.
//

#import "ZJPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface ZJPlayer (){
    id _playbackTimerObserver;
    NSTimeInterval _lastTime;
}

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVURLAsset *urlAsset;

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, strong) NSURL *url;

@end

static ZJPlayer *_manager = nil;
@implementation ZJPlayer

+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[ZJPlayer alloc] init];
    });
    return _manager;
}

- (void)pause{
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    if (!self.player) return;
    [self.player pause];
}

- (void)resume{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //默认情况下扬声器播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    if (!self.player) {
        [self setPlayerWithUrl:self.url];
        return;
    }
    [self.player play];
}

- (void)stop{
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.player removeTimeObserver:_playbackTimerObserver];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    if (!self.player) return;
    [self.player pause];
    
    self.urlAsset = nil;
    self.playerItem = nil;
    self.player = nil;
    self.playerState = ZJPlayerStatusUnknown;
}

// 快进【x】s
- (void)seekWithTimeInterval:(NSTimeInterval)timeInterval{
    NSTimeInterval seconds = CMTimeGetSeconds(self.player.currentItem.currentTime) +timeInterval;
    [self.player seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        
    }];
}

//【x】倍速播放
- (void)seekToProgress:(float)progress{
    NSTimeInterval seconds = CMTimeGetSeconds(self.player.currentItem.duration) * progress;
    [self.player seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        
    }];
    
}

- (void)setRate:(float)rate{
    self.player.rate = rate;
}

- (void)setMuted:(BOOL)muted{
    self.player.muted = muted;
}

- (void)setVolume:(float)volume{
    if (volume > 0.0) {
        self.muted = NO;
    }
    [self.player setVolume:volume];
}

- (void)playingWithResource:(ZJPlayerResourceType )resource url:(NSURL *)url isCache:(BOOL)isCache{
    if (isCache) return;   //暂时先不处理 缓存
    //远程资源
    _url = url;
    [self setPlayerWithUrl:self.url];
}

- (void)setPlayerWithUrl:(NSURL *)url{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //默认情况下扬声器播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    [self setUrlAssetWithUrl:url];
    [self addPeriodicTimeObserver];
    [self addKVOObserver];
}

- (void)setUrlAssetWithUrl:(NSURL *)url{
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey : @YES};
    _urlAsset = [AVURLAsset URLAssetWithURL:url options:options];
    NSArray *keys = @[@"duration"];
    [self.urlAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSError *error;
        AVKeyValueStatus tracksStatus = [self.urlAsset statusOfValueForKey:@"duration" error:&error];
        switch (tracksStatus) {
            case AVKeyValueStatusUnknown:
                if (self.playerState == ZJPlayerStatusUnknown) return;
//                NSLog(@"监听状态属性 AVPlayerItemStatusUnknown");
                self.playerState = ZJPlayerStatusUnknown;
                break;
            case AVKeyValueStatusLoading:
                if (self.playerState == ZJPlayerStatusBuffering) return;
//                NSLog(@"监听状态属性 AVKeyValueStatusLoading");
                self.playerState = ZJPlayerStatusBuffering;
                break;
            case AVKeyValueStatusLoaded:
                if (self.playerState == ZJPlayerStatusReadyToPlay) return;
//                NSLog(@"监听状态属性 AVKeyValueStatusLoaded");
                self.playerState = ZJPlayerStatusReadyToPlay;
                break;
            case AVKeyValueStatusFailed:
                if (self.playerState == ZJPlayerStatusFailed) return;
//                NSLog(@"监听状态属性 AVKeyValueStatusFailed");
                self.playerState = ZJPlayerStatusFailed;
                break;
            case AVKeyValueStatusCancelled:
                if (self.playerState == ZJPlayerStatusStopped) return;
//                NSLog(@"监听状态属性 AVKeyValueStatusCancelled");
                self.playerState = ZJPlayerStatusStopped;
                break;
                
            default:
                break;
        }
    }];
    
    [self setPlayerItemWithURLAsset:self.urlAsset];
}

- (void)setPlayerItemWithURLAsset:(AVURLAsset *)urlAsset{
    _playerItem = [AVPlayerItem playerItemWithAsset:urlAsset];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playToEndTime) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playSuspended) name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    [self setPlayerWithPlayerItem:self.playerItem];
}

- (void)playToEndTime{
    if (self.playerState == ZJPlayerStatusStopped) return;
//    NSLog(@"监听到播放结束了 AVPlayerItemDidPlayToEndTimeNotification");
    self.playerState = ZJPlayerStatusStopped;
    [self.playerItem seekToTime:kCMTimeZero];
    [self stop];
}

- (void)playSuspended{
//    NSLog(@"监听到播放被打断了 AVPlayerItemDidPlayToEndTimeNotification");
}

- (void)setPlayerWithPlayerItem:(AVPlayerItem *)playerItem{
    _player = [[AVPlayer alloc]initWithPlayerItem:playerItem];
    
}

- (void)addPeriodicTimeObserver{
//    __weak typeof(self) weakself = self;
    _playbackTimerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.f, 1.f) queue:NULL usingBlock:^(CMTime time) {
//        CGFloat progress = weakself.playerItem.currentTime.value / weakself.playerItem.currentTime.timescale;
//        NSLog(@"progress ==> %f",progress);
    }];
}

- (void)addKVOObserver{
    // 监听状态属性
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 监听网络加载情况属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    // 监听播放的区域缓存是否为空
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    // 缓存可以播放的时候调用
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    // 监听暂停或者播放中
    [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(upadte)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {                       // 监听状态属性
        AVPlayerItemStatus itemStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
    
        switch (itemStatus) {
            case AVPlayerItemStatusUnknown:
                if (self.playerState == ZJPlayerStatusUnknown) return;
//                NSLog(@"监听状态属性 AVPlayerItemStatusUnknown");
                self.playerState = ZJPlayerStatusUnknown;
                break;
            case AVPlayerItemStatusReadyToPlay:
                [self.player play]; // 达到播放状态自动播放
                if (self.playerState == ZJPlayerStatusReadyToPlay) return;
//                NSLog(@"监听状态属性 AVPlayerItemStatusReadyToPlay");
                self.playerState = ZJPlayerStatusReadyToPlay;
                break;
            case AVPlayerItemStatusFailed:
                if (self.playerState == ZJPlayerStatusFailed) return;
//                NSLog(@"监听状态属性 AVPlayerItemStatusFailed");
                self.playerState = ZJPlayerStatusFailed;
                break;
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {        //  监听播放器的下载进度
//        NSArray *loadedTimeRanges = [self.playerItem loadedTimeRanges];
//        // 获取缓冲区域
//        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
//        float startSeconds = CMTimeGetSeconds(timeRange.start);
//        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
//        // 计算缓冲总进度
//        NSTimeInterval timeInterval = startSeconds + durationSeconds;
//        CMTime duration = self.playerItem.duration;
//        CGFloat totalDuration = CMTimeGetSeconds(duration);
//        //缓存值
//        CGFloat bufferValue = timeInterval / totalDuration;
//        NSLog(@"监听播放器的下载进度 %f",bufferValue);
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {      //  监听播放器在缓冲数据的状态
        if (self.playerState == ZJPlayerStatusBuffering) return;
//        NSLog(@"监听播放器在缓冲数据的状态");
        self.playerState = ZJPlayerStatusBuffering;
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {   //  缓冲达到可播放
        if (self.playerState == ZJPlayerStatusReadyToPlay) return;
//        NSLog(@"缓冲达到可播放");
        self.playerState = ZJPlayerStatusReadyToPlay;
        
    } else if ([keyPath isEqualToString:@"rate"]){                       //  当rate==0时为暂停,rate==1时为播放,当rate等于负数时为回放
        if ([[change objectForKey:NSKeyValueChangeNewKey]integerValue] == 0) {
            if (self.playerState == ZJPlayerStatusStopped) return;
            self.playerState = ZJPlayerStatusStopped;
//            NSLog(@"暂停播放");
        }else{
            if (self.playerState == ZJPlayerStatusPlaying) return;
            self.playerState = ZJPlayerStatusPlaying;
//            NSLog(@"正在播放");
        }
    }
}



- (void)upadte{
//    NSTimeInterval current = CMTimeGetSeconds(self.player.currentTime);
//    if (current != _lastTime) {
//        if (self.playerState == ZJPlayerStatusPlaying) return;
//        self.playerState = ZJPlayerStatusPlaying;
//        NSLog(@"正在播放");
//    } else {
//        if (self.playerState == ZJPlayerStatusStopped) return;
//        self.playerState = ZJPlayerStatusStopped;
//        NSLog(@"暂停播放");
//    }
//    _lastTime = current;
}



- (void)setPlayerState:(ZJPlayerState)playerState{
    _playerState = playerState;
//    NSLog(@"playerState ==> %ld",self.playerState);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:playStateChanged:)]) {
            [self.delegate audioPlayer:self playStateChanged:self.playerState];
        }
    });
}

@end
