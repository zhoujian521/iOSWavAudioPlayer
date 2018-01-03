//
//  AudioResPlayer.m
//  iOSWavAudioPlayer
//
//  Created by BJQingniuJJ on 2017/12/15.
//  Copyright © 2017年 周建. All rights reserved.
//

#import "AudioResPlayer.h"

#import "AFFileDownLoader.h"
#import "FileManager.h"

#import "AudioTransTool.h"



#define KCachePath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]

@interface AudioResPlayer ()<ZJPlayerDelegate, AudioTransDelegate, AFFileDownLoaderDelegate>{
    NSURL *_url;
    void *_handle;  // 转码器对象句柄
}

// 转码【完成】文件路径
@property (nonatomic, copy) NSString *audioTransedFilePath;
// 转码ing中文件路径
@property (nonatomic, copy) NSString *audioTransingFilePath;
// 下载【完成】文件路径
@property (nonatomic, copy) NSString *downloadedFilePath;
// 下载器
@property (nonatomic, strong) AFFileDownLoader *downLoader;
// 播放器
@property (nonatomic, strong) AudioTransTool *audioTrans;
// 转码器
@property (nonatomic, strong) ZJPlayer *audioPlayer;

@property (nonatomic, strong) NSTimer *timer1s;

@property (nonatomic, assign) NSInteger timer1sCount;

@property (nonatomic, strong) NSString *timer1sText;


@end


@implementation AudioResPlayer

- (void)playingUrl:(NSURL *)url{
    _url = url;
    // 转码中中   cache/FileDownLoader/AudioTransing/url.lastCompent
    // 转码完成   cache/FileDownLoader/AudioTransed/url.lastCompent
    NSString *audioTransingFile = [[self getAudioTransingFilePath] stringByAppendingPathComponent:url.lastPathComponent];
    self.audioTransingFilePath = [audioTransingFile stringByReplacingOccurrencesOfString:@".wav" withString:@".mp3"];
    NSString *audioTransedFile  = [[self getAudioTransedFilePath] stringByAppendingPathComponent:url.lastPathComponent];
    self.audioTransedFilePath = [audioTransedFile stringByReplacingOccurrencesOfString:@".wav" withString:@".mp3"];
    
    // 02:已转码完成  转码未完成
    // 1. 判断当前url对应的资源是否已转码完毕, 如果已经转码完毕, 直接【播放本地资源】
    // 1.1 通过一些辅助信息, 去记录那些文件已经转码完毕(额外维护信息文件)
    // 1.2 转码中的文件路径 和  转码完成的文件路径分离
    if ([FileManager fileExistsAtPath:self.audioTransedFilePath]) {
        // 本地已经缓存转码完成的 MP3 文件 =》 播放
        [self playWithResPath:self.audioTransedFilePath];
        return;
    }
    
    if ([FileManager fileExistsAtPath:self.audioTransingFilePath]) {
        // 本地缓存转码ing的 MP3 文件 =》 删除
        [FileManager removeFileAtPath:self.audioTransingFilePath];
    }
    [self downLoadeWithUrl:url];
}

- (void)playWithResPath:(NSString *)mp3audioPath{
// #warning mark --- 0020：正在播放 ---
    NSURL *cacheUrl = [NSURL fileURLWithPath:mp3audioPath];
    [[ZJPlayer shareManager] playingWithResource:ZJPlayerResourceLocal url:cacheUrl isCache:NO];
}

- (void)pause{
     [self.audioPlayer pause];
}

- (void)stop{
     [self.audioPlayer stop];
}

- (void)downLoadeWithUrl:(NSURL *)url{
    [self initMemberVars];
    self.timer1sText = @"下载计时";
    [self fireTimer1s];
    // 调用下载类就可以了 ==》 已经对已下载
    __weak typeof(self) weakself = self;
    [self.downLoader downLoadWithFileUrl:url progress:^(CGFloat progress, long long fileTempSize, long long totalSize) {
// #warning mark --- 0000：正在下载资源 ---
//        NSLog(@"【progress】\nprogress => %.2f  \nfileTempSize => %lld  \ntotalSize => %lld",progress,fileTempSize,totalSize);
    } success:^(NSString *downloadedFilePath) {
        [self invalidateTimer1s];
        [self initMemberVars];
        NSLog(@"downloadedFilePath => %@",downloadedFilePath);
        weakself.downloadedFilePath = downloadedFilePath;
// #warning mark --- 0010：正在转码 ---
        [weakself audioWavToMP3];
    } failure:^(NSError *error) {
        NSLog(@"error => %@",[error localizedDescription]);
    }];
}


- (void)audioWavToMP3{
    [self initMemberVars];
    self.timer1sText = @"转码计时";
    [self fireTimer1s];
    [self.audioTrans audioToMP3WithSourcePath:self.downloadedFilePath aimPath:self.audioTransingFilePath];
    [self.audioTrans startAudioTrans];
}

#pragma mark --- ZJPlayerDelegate ---
- (void)audioPlayer:(ZJPlayer *)player playStateChanged:(ZJPlayerState)state{
    switch (state) {
        case ZJPlayerStatusUnknown:
// #warning mark --- 0021： 播放准备中 ---
            NSLog(@"未知状态");
            break;
        case ZJPlayerStatusFailed:
// #warning mark --- 0022： 播放失败 ---
            NSLog(@"播放失败");
            break;
        case ZJPlayerStatusBuffering:
// #warning mark --- 0023： 正在加载资源 ---
            NSLog(@"正在缓存");
            break;
        case ZJPlayerStatusReadyToPlay:
// #warning mark --- 0024： 加载完成可以播放 ---
            NSLog(@"加载完成可以播放");
            break;
        case ZJPlayerStatusPlaying:
// #warning mark --- 0025：正在播放 ---
            NSLog(@"正在播放");
            break;
        case ZJPlayerStatusStopped:
// #warning mark --- 0026： 暂停播放 ---
            NSLog(@"暂停播放");
            break;
            
        default:
            break;
    }
}

#pragma mark --- FileDownLoaderDelegate ---

- (void)downLoader:(AFFileDownLoader *)downLoader taskState:(AFSessionTaskState)taskState{
    switch (taskState) {
        case AFSessionTaskStateUnknow:    // 未知状态
            NSLog(@"AFSessionTaskStateUnknow ==> 未知状态");
            break;
        case AFSessionTaskStateRunning:    // 下载暂停
// #warning mark --- 0001： 暂停下载 ---
            NSLog(@"AFSessionTaskStateRunning ==> 正在下载");
            break;
        case AFSessionTaskStateSuspended:  // 正在下载
// #warning mark --- 0002： 正在下载---
            NSLog(@"AFSessionTaskStateSuspended ==> 暂停下载");
            break;
        case AFSessionTaskStateCanceling:  // 已经下载
// #warning mark --- 0003： 已经下载---
            NSLog(@"AFSessionTaskStateCanceling ==> 取消下载");
            break;
        case AFSessionTaskStateCompleted:   // 下载失败
// #warning mark --- 0004：下载失败---
            NSLog(@"AFSessionTaskStateCompleted ==> 下载完成");
            break;
        case AFSessionTaskStateFailure:   // 下载失败
// #warning mark --- 0004：下载失败---
            NSLog(@"AFSessionTaskStateFailure ==> 下载异常");
            break;
            
        default:
            break;
    }

}

#pragma mark --- AudioTransDelegate ---

- (void)audioTrans:(AudioTransTool *)audioTrans transFilePath:(NSString *)filePath {
    [self invalidateTimer1s];
    [self initMemberVars];
    NSLog(@"progress ==> 100 => 转码完成 可以播放");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.audioTrans stopAudioTrans];
        
        [self checkLocalRecordCacheSizeWithMaxSize:100.0f];
        
        [FileManager moveFileWithPath:filePath toPath:self.audioTransedFilePath];
        
        [FileManager removeFileAtPath:self.downloadedFilePath];

        [self playWithResPath:self.audioTransedFilePath];
    });
    
}
- (void)audioTrans:(AudioTransTool *)audioTrans errorCode:(NSInteger)code errorMsg:(NSString *)msg {
// #warning mark --- 0011：转码异常 code msg ---
    NSLog(@"code:%ld_msg:%@",code,msg);
    [self invalidateTimer1s];
    [self initMemberVars];
    
    [FileManager removeFileAtPath:self.downloadedFilePath];
}

- (void)audioTrans:(AudioTransTool *)audioTrans progress:(int)progress{
//    NSLog(@"progress ==> %d", progress);
}

- (void)checkLocalRecordCacheSizeWithMaxSize:(CGFloat)maxSize{
    NSString *path = [KCachePath stringByAppendingPathComponent:@"FileDownloader/AudioTransed"];
    CGFloat fileSize = [self getsRecordCacheSizeWithFilePath:path];
    
    while (fileSize > maxSize) {
        NSArray *recordFiles = [[NSFileManager defaultManager] subpathsAtPath:path];
        NSString *fileName = [recordFiles lastObject];
        NSString *filePath = [path stringByAppendingPathComponent:fileName];
        
        if ([FileManager fileSizeAtPath:filePath]) {
            [FileManager removeFileAtPath:filePath];
        }
        fileSize = [self getsRecordCacheSizeWithFilePath:path];
    }
    
}

- (CGFloat)getsRecordCacheSizeWithFilePath:(NSString *)path{
    // 总大小
    unsigned long long size = 0;
    NSFileManager *manager = [NSFileManager defaultManager];
    
    BOOL isDir = NO;
    BOOL exist = [manager fileExistsAtPath:path isDirectory:&isDir];
    
    // 判断路径是否存在
    if (!exist) return size;
    if (isDir) { // 是文件夹
        NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:path];
        for (NSString *subPath in enumerator) {
            NSString *fullPath = [path stringByAppendingPathComponent:subPath];
            size += [manager attributesOfItemAtPath:fullPath error:nil].fileSize;
        }
    } else { // 是文件
        size += [manager attributesOfItemAtPath:path error:nil].fileSize;
    }
    return size/1024.0/1024.0;
}


#pragma mark --- 计时器相关 ---
/**
 启用计时器
 */
- (void)fireTimer1s{
    if (self.timer1s.valid) {
        [self invalidateTimer1s];
    }
    [[NSRunLoop currentRunLoop] addTimer:self.timer1s forMode:NSRunLoopCommonModes];
    [self.timer1s fire];
}

/**
 销毁计时器
 */
- (void)invalidateTimer1s{
    [self.timer1s invalidate];
    self.timer1s = nil;
}


// 进入后台模式 =》 不会调用  currentRunLoop
- (NSTimer *)timer1s{
    if (!_timer1s) {
        _timer1s = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timer1s:) userInfo:nil repeats:YES];
    }
    return _timer1s;
}

/**
 每隔5s计时器回调一次
 
 @param sender 上报添加小结计时器
 */
- (void)timer1s:(NSTimer *)sender{
    self.timer1sCount += 1;
    NSString *timerText = [NSString stringWithFormat:@"%@ => 【%ld】",self.timer1sText,self.timer1sCount];
    NSLog(@"%@",timerText);
}

- (void)initMemberVars{
    self.timer1sCount = 0;
}


#pragma mark --- LazyLoding ---

- (AFFileDownLoader *)downLoader{
    if (!_downLoader) {
        _downLoader = [[AFFileDownLoader alloc] init];
        self.downLoader.delegate = self;
    }
    return _downLoader;
}

- (AudioTransTool *)audioTrans{
    if (!_audioTrans) {
        _audioTrans = [AudioTransTool audioTransToolWithSleeptime:10];
        self.audioTrans.delegate = self;
    }
    return _audioTrans;
}

- (ZJPlayer *)audioPlayer{
    if (!_audioPlayer) {
        _audioPlayer = [ZJPlayer shareManager];
        self.audioPlayer.delegate = self;
    }
    return _audioPlayer;
}


- (NSString *)getAudioTransingFilePath{
    NSString *path = [KCachePath stringByAppendingPathComponent:@"FileDownloader/AudioTransing"];
    BOOL isCreat = [FileManager createDirectoryIfNotExists:path];
    if (isCreat) return path;
    return @"";
}


- (NSString *)getAudioTransedFilePath{
    NSString *path = [KCachePath stringByAppendingPathComponent:@"FileDownloader/AudioTransed"];
    BOOL isCreat = [FileManager createDirectoryIfNotExists:path];
    if (isCreat) return path;
    return @"";
}


@end
