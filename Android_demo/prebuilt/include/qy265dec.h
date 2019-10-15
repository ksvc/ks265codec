///////////////////////////////////////////////////
//
//         KingSoft H265 Codec Library
//
//  Copyright(c) 2013-2014 KingSoft, Inc.
//              www.KingSoft.cn
//
///////////////////////////////////////////////////
/************************************************************************************
* decInf.h: interface of decoder for user
*
* \date     2013-09-28: first version
*
************************************************************************************/
#ifndef _QY265_DECODER_INTERFACE_H_
#define  _QY265_DECODER_INTERFACE_H_

#include "qy265def.h"

// config parameters for Decoder
typedef struct QY265DecConfig {
    void* pAuth;                //QYAuth, invalid if don't need aksk auth
    int threads;               // number of threads used in decoding (0: auto)
    int bEnableOutputRecToFile;  // For debug: write reconstruct YUV to File
    char* strRecYuvFileName;      // For debug: file name of YUV
                                  // when bEnableOutputRecToFile = 1
    int logLevel;               //For debug: log level
}QY265DecConfig;

// information of decoded frame
typedef struct QY265FrameInfo {
    int nWidth;     // frame width
    int nHeight;    // frame height
    long long pts;  // time stamp
    int bIllegalStream; // input bit stream is illegal
    int poc;
}QY265FrameInfo;

// decoded frame with data and information
typedef struct QY265Frame {
    int  bValid; //if == 0, no more valid output frame
    unsigned char* pData[3]; // Y U V
    short iStride[3];        // stride for each component
    QY265FrameInfo frameinfo;
#ifdef EMSCRIPTEN//TEST_YUVPLANE
    unsigned char* pYUVPlane; //liner buffer for yuv 420p 
#endif
}QY265Frame;


#if defined(__cplusplus)
extern "C" {
#endif//__cplusplus

/************************************************************************************
* I/F for all usrs
************************************************************************************/
// create decoder, return  handle of decoder
_h_dll_export void* QY265DecoderCreate(QY265DecConfig* pDecConfig, int * pStat);
// destroy decoder with specific handle
_h_dll_export void QY265DecoderDestroy(void* pDecoder);
// set config to specific decoder
_h_dll_export void QY265DecoderSetDecConfig(void *pDecoder, QY265DecConfig* pDecConfig, int * pStat);
//the input of this function should be one or more NALs;
//if only one NAL, with or without start bytes are both OK
_h_dll_export void QY265DecodeFrame(void *pDecoder, unsigned char* pData, int iLen, int * pStat, const long long pts);
// bSkip = false : same as QY265DecodeFrame
// bSkip = true : only decode slice headers in pData, slice data skipped
_h_dll_export void QY265DecodeFrameEnSkip(void *pDecoder, unsigned char* pData, int iLen, int * pStat, const long long pts, int bSkip);
//flush decoding, called at end
_h_dll_export void QY265DecodeFlush(void *pDecoder, int bClearCachedPics, int * pStat);
// retrieve the output, the function are used for synchronized output, this function need to call several time until get NULL
// if bForceLogo == true, only one frame buffer inside, need  return before get next output
_h_dll_export void QY265DecoderGetDecodedFrame(void *pDecoder, QY265Frame* pFrame, int * pStat, int bForceLogo);
// return the frame buffer which QY265DecoderGetOutput get from decoder, each valid QY265DecoderGetOutput should match with a ReturnFrame
_h_dll_export void QY265DecoderReturnDecodedFrame( void *pDecoder, QY265Frame* pFrame);

/**
 * dump latest decoded VUI parameters
 * @param_input pDecoder:   decoder instance
 * @param_output vui:       fill with decoded vui parameters
 * @param_output bValid: =0 if no valid vui parameters decoded,
 *                      otherwise =1
 */
_h_dll_export void QY265DumpVUIParameters(void* pDecoder, vui_parameters* vui, int* bValid);

#if defined(__cplusplus)
}
#endif//__cplusplus

#endif//header
