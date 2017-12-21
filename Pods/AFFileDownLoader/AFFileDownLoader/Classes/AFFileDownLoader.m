//
//  AFFileDownLoader.m
//  iOSWavAudioPlayer
//
//  Created by BJQingniuJJ on 2017/12/19.
//  Copyright © 2017年 周建. All rights reserved.
//

#import "AFFileDownLoader.h"
#import "FileManager.h"
#import "AFNetworking.h"

#define KCachePath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]

@interface AFFileDownLoader (){
    NSURL *_fileUrl;
    /** 当前下载长度 */
    long long _fileTempSize;
    /** 文件的总长度 */
    long long _totalSize;
}

// 下载【完成】文件路径
@property (nonatomic, copy) NSString *downloadedFilePath;
// 下载ing中文件路径
@property (nonatomic, copy) NSString *downloadingFilePath;

/** AFNetworking断点下载（支持离线）需用到的属性 **********/
// 文件输出流
@property (nonatomic, strong) NSOutputStream *outputStream;
/* AFURLSessionManager */
@property (nonatomic, strong) AFURLSessionManager *manager;
/** 下载任务 */
@property (nonatomic, strong) NSURLSessionDataTask *sessionDataTask;

@end


@implementation AFFileDownLoader

- (void)downLoadWithFileUrl:(NSURL *)fileUrl progress:(AFFileDownLoadingProgressBlock )progress success:(AFFileDownLoadedSuccessBlock )success failure:(AFFileDownLoadedFailureBlock)failure{
    self.state = AFSessionTaskStateUnknow;
    
    _fileUrl = fileUrl;
    
    self.progressBlock = progress;
    self.successBlock = success;
    self.failureBlock = failure;
    
    // 00:存储机制
    self.downloadingFilePath = [[self getDownloadingFilePath] stringByAppendingPathComponent:fileUrl.lastPathComponent];
    self.downloadedFilePath = [[self getDownloadedFilePath]  stringByAppendingPathComponent:fileUrl.lastPathComponent];

    // 02:已下载 未下载
    if ([FileManager fileExistsAtPath:self.downloadedFilePath]) {
        self.state = AFSessionTaskStateCompleted;
        if (self.successBlock) {
            self.successBlock(self.downloadedFilePath);
        }
        return;
    }
    // 02:断点续传
    // 2. 检测, 本地有没有下载过临时缓存,
    // 2.1 没有本地缓存, 从0字节开始下载(断点下载 HTTP, RANGE "bytes=开始-"), return
    if (![FileManager fileExistsAtPath:self.downloadingFilePath]) {
        _fileTempSize = 0;
        [self downLoadWithFileUrl:fileUrl offset:_fileTempSize];
        return;
    }
    // 2.2 获取本地缓存的大小ls 【localSize】: 文件真正正确的总大小rs【remoteSize】
    _fileTempSize = [FileManager fileSizeAtPath:self.downloadingFilePath];
    [self downLoadWithFileUrl:fileUrl offset:_fileTempSize];
}


- (void)downLoadWithFileUrl:(NSURL *)fileUrl offset:(long long)offset{
    NSLog(@"\n下载Url => %@ \n 下载偏移offset => %lld", fileUrl, offset);
    // 1.创建下载URL
    // _fileUrl ==> Url
    
    // 2.创建request请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileUrl];
    // 设置HTTP请求头中的Range
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", offset];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    __weak typeof(self) weakself = self;
    self.sessionDataTask = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [weakself.outputStream close];
        if (!error) {
            self.state = AFSessionTaskStateCompleted;
            [FileManager moveFileWithPath:weakself.downloadingFilePath toPath:weakself.downloadedFilePath];
            if (weakself.successBlock) {
                self.successBlock(weakself.downloadedFilePath);
            }
            return ;
        }
        self.state = AFSessionTaskStateFailure;
        if (weakself.failureBlock) {
            weakself.failureBlock(error);
        }
        // 初始化设置
        [weakself initMemberVars];
    }];
    [self.sessionDataTask resume];
    
#pragma mark --- 写入文件 ----
    [self.manager setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
        weakself.state = AFSessionTaskStateRunning;
        // 获得下载文件的总长度：请求下载的文件长度 + 当前已经下载的文件长度
        _totalSize = response.expectedContentLength + _fileTempSize;
        // 创建/打开文件输出流
        weakself.outputStream = [NSOutputStream outputStreamToFileAtPath:weakself.downloadingFilePath append:YES];
        [weakself.outputStream open];
        // 允许处理服务器的响应，才会继续接收服务器返回的数据
        return NSURLSessionResponseAllow;
    }];
    
    
#pragma mark --- 下载数据 进度相关处理
    [self.manager setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
        weakself.state = AFSessionTaskStateRunning;
        // 文件写入
        [weakself.outputStream write:data.bytes maxLength:data.length];
        // 拼接文件总长度
        _fileTempSize += data.length;
                
        // 进度大部分情况下会跟随UI刷新 ==> 获取主线程，不然无法正确显示进度。
        NSOperationQueue* mainQueue = [NSOperationQueue mainQueue];
        [mainQueue addOperationWithBlock:^{
            if (weakself.progressBlock) {
                weakself.progressBlock(1.0 * weakself.sessionDataTask.countOfBytesReceived / weakself.sessionDataTask.countOfBytesExpectedToReceive, weakself.sessionDataTask.countOfBytesReceived, weakself.sessionDataTask.countOfBytesExpectedToReceive);
            }
        }];
    }];
}

- (void)cancel{
    [self.sessionDataTask cancel];
    self.state = AFSessionTaskStateCanceling;
}

- (void)resume{
    [self.sessionDataTask resume];
}

- (void)suspend{
    [self.sessionDataTask suspend];
    self.state = AFSessionTaskStateSuspended;
}

- (void)setState:(AFSessionTaskState)state{
    if (self.state == state) return;
    _state = state;
    if (self.delegate && [self.delegate respondsToSelector:@selector(downLoader:taskState:)]) {
        [self.delegate downLoader:self taskState:self.state];
    }
}

- (int64_t)countOfBytesReceived{
    return self.sessionDataTask.countOfBytesReceived;
}

- (int64_t)countOfBytesExpectedToReceive{
    return self.sessionDataTask.countOfBytesReceived;
}
/**
 * manager的懒加载
 */
- (AFURLSessionManager *)manager {
    if (!_manager) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 1. 创建会话管理者
        _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        self.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    return _manager;
}


- (NSString *)getDownloadingFilePath{
    NSString *path = [KCachePath stringByAppendingPathComponent:@"FileDownloader/AudioDownloading"];
    BOOL isCreat = [FileManager createDirectoryIfNotExists:path];
    if (isCreat) return path;
    return @"";
}


- (NSString *)getDownloadedFilePath{
    NSString *path = [KCachePath stringByAppendingPathComponent:@"FileDownloader/AudioDownloaded"];
    BOOL isCreat = [FileManager createDirectoryIfNotExists:path];
    if (isCreat) return path;
    return @"";
}

- (void)initMemberVars{
    _totalSize = 0;
    _fileTempSize = 0;
    [FileManager removeFileAtPath:self.downloadingFilePath];
    [FileManager removeFileAtPath:self.downloadedFilePath];
}

@end
