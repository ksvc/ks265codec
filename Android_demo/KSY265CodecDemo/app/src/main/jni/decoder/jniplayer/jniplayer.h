#ifndef __JNIPLAYER_H__
#define __JNIPLAYER_H__

struct VideoFrame
{
	int width;
	int height;
	int linesize_y;
	int linesize_uv;
	double pts;
	uint8_t *yuv_data[3];
};

uint32_t getms();

#endif /* __JNIPLAYER_H__ */
