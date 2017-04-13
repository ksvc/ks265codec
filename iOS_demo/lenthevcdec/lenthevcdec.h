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

	typedef struct lenthevcdec_frame {
		/* size in byte of this struct, initialized by caller for expand */
		int32_t size;
		/* width & height: picture size */
		int32_t width;
		int32_t height;
		/* line_stride & pixels: output picture pixel data */
		int32_t line_stride[3];
		void* pixels[3];
		/* bit depth of output picture pixel */
		int32_t bit_depth;
		/* return 1 if we got frame, then the pixels & line_stride & got_pts is valid */
		int32_t got_frame;
		/* pts of output frame */
		int64_t got_pts;
		/* 0 progressive, 1 top, 2 bottom */
		int32_t pic_struct;
		/* Sample Aspect Ratio */
		int32_t sar_width;
		int32_t sar_height;
	} lenthevcdec_frame;

	typedef void* lenthevcdec_ctx;

	int             LENTAPI lenthevcdec_version(void);

	lenthevcdec_ctx LENTAPI lenthevcdec_create(int threads, int compatibility, void* reserved);

	void            LENTAPI lenthevcdec_destroy(lenthevcdec_ctx ctx);

	void            LENTAPI lenthevcdec_flush(lenthevcdec_ctx ctx);

	/* bs & bs_len: intput bitstream
	 * pts: input play timestamp
	 * out_frame: output picture warpper
	 * return: byte count used by decoder, or negative number for error
	 */
	int             LENTAPI lenthevcdec_decode_frame(lenthevcdec_ctx ctx,
							 const void* bs, int bs_len,
							 int64_t pts,
							 lenthevcdec_frame *out_frame);

#ifdef __cplusplus
}
#endif

#endif/*__LENTHEVCDEC_H__*/
