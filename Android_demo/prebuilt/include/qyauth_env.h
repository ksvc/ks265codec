
#ifndef _KS_AUTH_ENV_H_
#define _KS_AUTH_ENV_H_

#if !defined(WIN32)
#include <stdint.h>
#endif

#define MAX_URL_LEN 2048
#define MAX_LEN 512
#define AUTH_ADDR_NUM 3
//***********************************
//* KSPrivateAuthEnv used as AUTH struct
//* when private server auth method is adopted
//***********************************
#ifndef KSAUTH_PRIVATE_AUTH
#define KSAUTH_PRIVATE_AUTH 0
#endif

//***********************************
//for Android, TCounterEnv used as AUTH struct
//when adopt Count auth method
#ifndef __PLATFORM_COUNTER_ENV__
#define __PLATFORM_COUNTER_ENV__

#ifdef ANDROID
#include <jni.h>
typedef struct _TCounterEnv
{
    JavaVM *jvm;
    jobject context;
}TCounterEnv;
#endif

#endif

#ifdef WIN32
#define _ks_dll_export   __declspec(dllexport)
#else // for GCC
#define _ks_dll_export __attribute__ ((visibility("default")))
#endif
_ks_dll_export extern const char strKsc265AuthVersion[];

#endif //header
