#include <sys/types.h>

void ConvertYCbCrToRGB565_neon( const uint8_t* y_buf,
		                   const uint8_t* u_buf,
		                   const uint8_t* v_buf,
		                   uint8_t* rgb_buf,
		                   int pic_width,
		                   int pic_height,
		                   int y_stride,
		                   int uv_stride,
		                   int rgb_stride,
						   int yuv_type);

void ConvertYCbCrToRGB565_c( const uint8_t* y_buf,
		                   const uint8_t* u_buf,
		                   const uint8_t* v_buf,
		                   uint8_t* rgb_buf,
		                   int pic_width,
		                   int pic_height,
		                   int y_stride,
		                   int uv_stride,
		                   int rgb_stride,
						   int yuv_type);

void ConvertYCbCrToRGB565( const uint8_t* y_buf,
		                   const uint8_t* u_buf,
		                   const uint8_t* v_buf,
		                   uint8_t* rgb_buf,
		                   int pic_width,
		                   int pic_height,
		                   int y_stride,
		                   int uv_stride,
		                   int rgb_stride,
		                   int yuv_type);
