//
//  AudioTranscodeAPI.h
//  AudioTranscode
//
//  Created by luoting on 2017/12/10.
//  Copyright © 2017年 wangcheng. All rights reserved.
//

#ifndef AudioTranscodeAPI_h
#define AudioTranscodeAPI_h

#include "AudioTranscodeCommeDef.h"

/*
 * @brief 获取转码器对象句柄
 * @param pUserData 附带数据
 * @param sleeptime 循环睡眠时间(单位:us)，该值与CPU使用率成反比，与转码时间成正比(例如，设置为500us，CPU为50%)
 * @return 成功返回转码器对象句柄；失败返回NULL
 */
void * CreateAudioTranscoder(void *pUserData, int sleeptime);

/*
 * @brief 设置转码的源文件以及目标文件的路径
 * @param handle 转码器对象句柄
 * @param sourcePath 转码的源文件，文件路径应该具有完整的文件名以及文件类型后缀
 * @param aimPath 转码的目标文件，文件路径应该具有完整的文件名以及文件类型后缀
 * @return 成功返回0；失败返回错误码
 */
int setAudioTranscoderFilePath(void * handle, const char * sourcePath, const char * aimPath);

/*
 * @brief 设置状态回调
 * @param handle 转码器对象句柄
 * @param callback 回调函数
 * @return 成功返回0；失败返回错误码
 *
 * 备注：callback 的回调信息 message
 * if message < 0xFF => 此时，message 的值时运行状态码，如AT_TRABSCODE_SUCCESS_FINISH等
 * if message >= 0xFF => 此时，message 的值代表的是转码进度，进度百分比 = message - 0xFF
 * 注意，转码的进度不会回调100%，如果解码完成将直接回调AT_TRABSCODE_SUCCESS_FINISH
 */
int setMessageCallBack(void * handle, PostMessageCallBack callback);

/*
 * @brief 开始转码
 * @param handle 转码器对象句柄
 * @return 成功返回0；失败返回错误码
 */
int startAudioTranscoder(void * handle);

/*
 * @brief 停止转码
 * @param handle 转码器对象句柄
 * @return 成功返回0；失败返回错误码
 */
int stopAudioTranscoder(void * handle);

/*
 * @brief 销毁转码器
 * @param handle 转码器对象句柄
 * @return 成功返回0；失败返回错误码
 */
int DestroyAudioTranscoder(void * handle);

#endif /* AudioTranscodeAPI_h */
