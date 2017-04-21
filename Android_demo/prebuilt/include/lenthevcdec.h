#ifndef __LENTHEVCDEC_H__
#define __LENTHEVCDEC_H__


#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

#if defined(_WIN32) || defined(WIN32)
	#define LENTAPI __stdcall
#else
	#define LENTAPI
#endif

	typedef void* lenthevcdec_ctx;

	int             LENTAPI lenthevcdec_version(void);

	lenthevcdec_ctx LENTAPI lenthevcdec_create(int threads, int compatibility, void* reserved);

	void            LENTAPI lenthevcdec_destroy(lenthevcdec_ctx ctx);

	void            LENTAPI lenthevcdec_flush(lenthevcdec_ctx ctx);

	/* bs & bs_len: intput bitstream
	 * pts: input play timestamp
	 * got_frame: return 1 if we got frame, then the pixels & line_stride & got_pts is valid
	 * width & height: picture size
	 * line_stride & pixels: output picture pixel data
	 * got_pts: pts of output frame
	 * return: byte count used by decoder, or negative number for error
	 */
	int             LENTAPI lenthevcdec_decode_frame(lenthevcdec_ctx ctx,
							 const void* bs, int bs_len,
							 int64_t pts,
							 int* got_frame,
							 int* width, int* height,
							 int line_stride[3], 
							 void* pixels[3], 
							 int64_t* got_pts);

#ifdef __cplusplus
}
#endif

#endif/*__LENTHEVCDEC_H__*/
