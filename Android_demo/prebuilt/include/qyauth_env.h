
#ifndef _KS_AUTH_ENV_H_
#define _KS_AUTH_ENV_H_

#define MAX_URL_LEN 2048
#define MAX_LEN 512
#define AUTH_ADDR_NUM 3
//***********************************
//* KSPrivateAuthEnv used as AUTH struct
//* when private server auth method is adopted
//***********************************
#ifndef KSAUTH_PRIVATE_AUTH
#define KSAUTH_PRIVATE_AUTH 1
#endif
#if KSAUTH_PRIVATE_AUTH
typedef struct _KSPrivateAuthEnv{
    //url of private auth server
    char priv_auth_server_url[AUTH_ADDR_NUM][MAX_URL_LEN];
    //aukey file path
    char priv_auth_key_path[MAX_LEN];
}KSPrivateAuthEnv;
#endif


static inline void parsePrivateAuthServerUrls(char* s, KSPrivateAuthEnv* pAuth)
{
    char* start = s;
    char* end = s;
    int i = 0;
    for ( i = 0; i < 3; ++i)
    {
        end = strchr(start,',');
        if (end == NULL)
        {
            strncpy(pAuth->priv_auth_server_url[i],start,strlen(start));
            ++i;
            break;
        }else{
            strncpy(pAuth->priv_auth_server_url[i],start,(intptr_t)(end - start));
        }
        start=end+1;
    }
    for ( ; i < 3; ++i)
    {
        pAuth->priv_auth_server_url[i][0]='\0';
    }
}

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

#endif //header
