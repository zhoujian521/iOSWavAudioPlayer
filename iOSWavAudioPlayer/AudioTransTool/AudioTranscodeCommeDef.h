//
//  AudioTranscodeCommeDef.h
//  AudioTranscode
//
//  Created by luoting on 2017/12/10.
//  Copyright © 2017年 wangcheng. All rights reserved.
//

#ifndef AudioTranscodeCommeDef_h
#define AudioTranscodeCommeDef_h

typedef void(*PostMessageCallBack)(void *pUserData, int message);

// 函数返回错误码
enum
{
    AT_ERR_OK = 0,                              // 无错误
    AT_ERR_INVALID_ARG = -1,                    // 无效参数

};

// 转码回调信息
enum{
    AT_TRABSCODE_SUCCESS_FINISH = 1,            // 转码成功
    AT_TRABSCODE_CANNOT_OPENINPUTFILE = -20,    // 无法打开源文件
    AT_TRABSCODE_CANNOT_OPENOUTPUTFILE = -21,   // 无法打开目标文件
    AT_TRABSCODE_FFMPEG_INITFAIL = -22,         // FFMPEG初始化错误
    AT_TRABSCODE_FFMPEG_RUNTIMEREEOE = -23      // FFMPEG转码运行时错误
};

#endif /* AudioTranscodeCommeDef_h */
