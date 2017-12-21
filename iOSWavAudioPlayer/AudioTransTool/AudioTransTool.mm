//
//  AudioTransTool.m
//  WavToMp3
//
//  Created by BJQingniuJJ on 2017/12/13.
//  Copyright © 2017年 周建. All rights reserved.
//

#import "AudioTransTool.h"
#import "AudioTranscodeAPI.h"

@interface AudioTransTool (){
    void *handle;  // 转码器对象句柄
    int sleeptime; // 循环睡眠时间(单位:us)
}

@property (nonatomic, strong) NSString *aimPath;

@end

@implementation AudioTransTool

static void messagecallback(void *pUserData, int message){
    AudioTransTool *user = (__bridge AudioTransTool *)pUserData;
    int progress = 0;
    if (message == AT_TRABSCODE_SUCCESS_FINISH) { // -1
        dispatch_async(dispatch_get_main_queue(), ^{
            if (user.delegate && [user.delegate respondsToSelector:@selector(audioTrans:transFilePath:)]) {
                [user.delegate audioTrans:user transFilePath:user.aimPath];
            }
        });
    } else if(message >= 0xFF){ // 转码进度 1-99
        progress = message - 0xFF;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (user.delegate && [user.delegate respondsToSelector:@selector(audioTrans:progress:)]) {
                [user.delegate audioTrans:user progress:progress];
            }
        });
    } else { // -20  -21   -22   -23
        progress = message - 0xFF;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *errorMsg = [user getErrorMsgWithErrorCode:progress];
            if (user.delegate && [user.delegate respondsToSelector:@selector(audioTrans:errorCode:errorMsg:)]) {
                [user.delegate audioTrans:user errorCode:progress errorMsg:errorMsg];
            }
        });
    }
}

- (instancetype)initWithSleeptime:(int)sleeptime{
    if (self = [super init]) {
        self->sleeptime = sleeptime;
        handle = CreateAudioTranscoder((__bridge void *)self, self->sleeptime);
    }
    return self;
}

+ (instancetype)audioTransToolWithSleeptime:(int)sleeptime{
    return [[AudioTransTool alloc] initWithSleeptime:sleeptime];
}

- (int)audioToMP3WithSourcePath:(NSString *)sourcePath aimPath:(NSString *)aimPath{
    self.aimPath = aimPath;
    if ((self->handle) == nil || self->handle == NULL) {
        return -1001;
    }
    int ret = setAudioTranscoderFilePath(self->handle, sourcePath.UTF8String, aimPath.UTF8String);
    if (ret) return ret;
    setMessageCallBack(self->handle, messagecallback);
    return ret;
}

- (int)startAudioTrans{
    return startAudioTranscoder(self->handle);
}

- (int)stopAudioTrans{
    int ret = stopAudioTranscoder(self->handle);
    if (ret) return ret;
    ret = DestroyAudioTranscoder(self->handle);
    return ret;
}

//AT_TRABSCODE_SUCCESS_FINISH = 1,            // 转码成功
//AT_TRABSCODE_CANNOT_OPENINPUTFILE = -20,    // 无法打开源文件
//AT_TRABSCODE_CANNOT_OPENOUTPUTFILE = -21,   // 无法打开目标文件
//AT_TRABSCODE_FFMPEG_INITFAIL = -22,         // FFMPEG初始化错误
//AT_TRABSCODE_FFMPEG_RUNTIMEREEOE = -23      // FFMPEG转码运行时错误
- (NSString *)getErrorMsgWithErrorCode:(NSInteger)code{
    switch (code) {
        case -20:
            return @"无法打开源文件";
            break;
        case -21:
            return @"无法打开目标文件";
            break;
        case -22:
            return @"FFMPEG初始化错误";
            break;
        case -23:
            return @"FFMPEG转码运行时错误";
            break;
        default:
            break;
    }
    return @"未定义异常码";
}

@end
