//
// Created by sujia on 2017/3/29.
//

#ifndef KSY265CODECDEMO_LOG_H
#define KSY265CODECDEMO_LOG_H

#include <android/log.h>

#define LOGD(fmt, args...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, fmt, ##args)
#define LOGI(fmt, args...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, fmt, ##args)
#define LOGW(fmt, args...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, fmt, ##args)
#define LOGE(fmt, args...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, fmt, ##args)

#endif //KSY265CODECDEMO_LOG_H
