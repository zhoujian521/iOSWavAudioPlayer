//
//  AudioTransTool.h
//  WavToMp3
//
//  Created by BJQingniuJJ on 2017/12/13.
//  Copyright © 2017年 周建. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AudioTransTool;
@protocol AudioTransDelegate <NSObject>

@required
/**
 转码成功回调

 @param audioTrans AudioTransTool
 @param filePath 转码后的.mp3文件路径
 */
- (void)audioTrans:(AudioTransTool *)audioTrans transFilePath:(NSString *)filePath;

@optional

/**
 转码进度回调
 if message < 0xFF => 此时，message 的值时运行状态码，如AT_TRABSCODE_SUCCESS_FINISH等
 if message >= 0xFF => 此时，message 的值代表的是转码进度，进度百分比 = message - 0xFF
 注意，转码的进度不会回调100%，如果解码完成将直接回调AT_TRABSCODE_SUCCESS_FINISH
 @param audioTrans AudioTransTool
 @param progress 转码进度
 */
- (void)audioTrans:(AudioTransTool *)audioTrans progress:(int)progress;

/**
 转码失败回调
 
 @param audioTrans AudioTransTool
 @param code 异常码
 @param msg 异常描述
 */
- (void)audioTrans:(AudioTransTool *)audioTrans errorCode:(NSInteger )code errorMsg:(NSString *)msg;

@end;

@interface AudioTransTool : NSObject

@property (nonatomic, weak) id<AudioTransDelegate> delegate;


/**
 创建【音频】转码器对象

 @param sleeptime 循环睡眠时间(单位:us)，该值与CPU使用率成反比，与转码时间成正比(例如，设置为500us，CPU为50%)  =》 sleeptime越大 转码越慢
 @return 【音频】转码器对象
 */
+ (instancetype)audioTransToolWithSleeptime:(int)sleeptime;


/**
 设置转码的源文件以及目标文件的路径

 @param sourcePath 转码的源文件，文件路径应该具有完整的文件名以及文件类型后缀
 @param aimPath  转码的目标文件，文件路径应该具有完整的文件名以及文件类型后缀
 @return 成功返回0； 失败返回错误码；
 */
- (int)audioToMP3WithSourcePath:(NSString *)sourcePath aimPath:(NSString *)aimPath;

/**
 开始转码
 
 @return 成功返回0；失败返回错误码
 */
- (int)startAudioTrans;


/**
 停止转码

 @return 成功返回0；失败返回错误码
 */
- (int)stopAudioTrans;

@end
