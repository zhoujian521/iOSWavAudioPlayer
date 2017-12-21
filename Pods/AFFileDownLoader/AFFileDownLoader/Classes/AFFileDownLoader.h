//
//  AFFileDownLoader.h
//  iOSWavAudioPlayer
//
//  Created by BJQingniuJJ on 2017/12/19.
//  Copyright © 2017年 周建. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AFSessionTaskState) {
    AFSessionTaskStateUnknow = 1,       // 未知状态
    AFSessionTaskStateRunning,          // 正在下载
    AFSessionTaskStateSuspended,        // 暂停下载
    AFSessionTaskStateCanceling,        // 取消下载
    AFSessionTaskStateCompleted,        // 下载完成
    AFSessionTaskStateFailure,          // 下载异常
};

typedef void(^AFFileDownLoadingProgressBlock)(CGFloat progress,long long fileTempSize, long long totalSize);
typedef void(^AFFileDownLoadedSuccessBlock)(NSString *downloadedFilePath);
typedef void(^AFFileDownLoadedFailureBlock)(NSError *error);

@class AFFileDownLoader;
@protocol AFFileDownLoaderDelegate <NSObject>

/**
 下载状态回调

 @param downLoader 下载器
 @param taskState 下载状态
 */
- (void)downLoader:(AFFileDownLoader *)downLoader taskState:(AFSessionTaskState )taskState;

@end;

@interface AFFileDownLoader : NSObject

@property (nonatomic, assign) id<AFFileDownLoaderDelegate> delegate;
// 下载状态
@property (nonatomic, assign, readonly) AFSessionTaskState state;
// 下载进度状态
@property (nonatomic, copy) AFFileDownLoadingProgressBlock progressBlock;
// 下载成功状态
@property (nonatomic, copy) AFFileDownLoadedSuccessBlock successBlock;
// 下载失败状态
@property (nonatomic, copy) AFFileDownLoadedFailureBlock failureBlock;

@property (readonly) int64_t countOfBytesReceived;

@property (readonly) int64_t countOfBytesExpectedToReceive;

/**
 根据Url下载

 @param fileUrl 文件地址
 @param progress 下载进度回调
 @param success 下载成功回调
 @param failure 下载失败回调
 */
- (void)downLoadWithFileUrl:(NSURL *)fileUrl progress:(AFFileDownLoadingProgressBlock )progress success:(AFFileDownLoadedSuccessBlock )success failure:(AFFileDownLoadedFailureBlock)failure;

/**
 取消下载
 */
- (void)cancel;

/**
 继续下载
 */
- (void)resume;

/**
 暂停下载
 */
- (void)suspend;


@end
