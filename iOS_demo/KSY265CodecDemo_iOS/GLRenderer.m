//
//  GLRenderer.m
//  HEVDecoder
//
//  Created by Shengbin Meng on 11/21/13.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "GLRenderer.h"
#import "MoviePlayer.h"
#import <GLKit/GLKit.h>

#define ENABLE_LOGD 0
#if ENABLE_LOGD
#define LOGD(...)  printf(__VA_ARGS__)
#else
#define LOGD(...)
#endif
#define LOGI LOGD
#define LOGE LOGD

static const char gVertexShader[] =
"attribute vec4 a_position;\n"
"attribute vec2 a_texCoord;\n"
"varying vec2 v_tc;\n"
"void main()\n"
"{\n"
"	gl_Position = a_position;\n"
"	v_tc = a_texCoord;\n"
"}\n";

static const char gFragmentShader[] =
"varying lowp vec2 v_tc;\n"
"uniform sampler2D u_texY;\n"
"uniform sampler2D u_texU;\n"
"uniform sampler2D u_texV;\n"
"void main(void)\n"
"{\n"
"mediump vec3 yuv;\n"
"lowp vec3 rgb;\n"
"yuv.x = texture2D(u_texY, v_tc).r;\n"
"yuv.y = texture2D(u_texU, v_tc).r - 0.5;\n"
"yuv.z = texture2D(u_texV, v_tc).r - 0.5;\n"
"rgb = mat3( 1,   1,   1,\n"
"0,       -0.39465,  2.03211,\n"
"1.13983,   -0.58060,  0) * yuv;\n"
"gl_FragColor = vec4(rgb, 1);\n"
"}\n";

static void printGLString(const char *name, GLenum s) {
    LOGI("GL %s = %s\n", name, glGetString(s););
}

static GLuint loadShader(GLenum shaderType, const char* pSource) {
    GLuint shader = glCreateShader(shaderType);
    if (shader) {
        glShaderSource(shader, 1, &pSource, NULL);
        glCompileShader(shader);
        GLint compiled = 0;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
        if (!compiled) {
            GLint infoLen = 0;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
            if (infoLen) {
                char* buf = (char*) malloc(infoLen);
                if (buf) {
                    glGetShaderInfoLog(shader, infoLen, NULL, buf);
                    LOGE("Could not compile shader %d:\n%s\n",
                         shaderType, buf);
                    free(buf);
                }
                glDeleteShader(shader);
                shader = 0;
            }
        }
    }
    return shader;
}

static GLuint createProgram(const char* pVertexSource, const char* pFragmentSource) {
    GLuint vertexShader = loadShader(GL_VERTEX_SHADER, pVertexSource);
    if (!vertexShader) {
        return 0;
    }
    
    GLuint fragmentShader = loadShader(GL_FRAGMENT_SHADER, pFragmentSource);
    if (!fragmentShader) {
        return 0;
    }
    
    GLuint program = glCreateProgram();
    if (program) {
        glAttachShader(program, vertexShader);
        glAttachShader(program, fragmentShader);
        glLinkProgram(program);
        GLint linkStatus = GL_FALSE;
        glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
        if (linkStatus != GL_TRUE) {
            GLint bufLength = 0;
            glGetProgramiv(program, GL_INFO_LOG_LENGTH, &bufLength);
            if (bufLength) {
                char* buf = (char*) malloc(bufLength);
                if (buf) {
                    glGetProgramInfoLog(program, bufLength, NULL, buf);
                    LOGE("Could not link program:\n%s\n", buf);
                    free(buf);
                }
            }
            glDeleteProgram(program);
            program = 0;
        }
    }
    return program;
}

static GLfloat vertexPositions[] = {
	-1.0, -1.0, 0.0,
    1.0, -1.0, 0.0,
	-1.0,  1.0, 0.0,
    1.0,  1.0, 0.0
};

static GLfloat textureCoords[] = {
	0.0, 1.0,
	1.0, 1.0,
	0.0, 0.0,
	1.0, 0.0
};


@implementation GLRenderer

{
    EAGLContext *context;
    
    GLint backingWidth, backingHeight;
    
    GLuint defaultFramebuffer, colorRenderbuffer;
    
    GLuint gProgram;
    GLuint gTexIds[3];
    GLuint gAttribPosition;
    GLuint gAttribTexCoord;
    GLuint gUniformTexY;
    GLuint gUniformTexU;
    GLuint gUniformTexV;
    
    id<RenderStateListener> listener;
    
    int needSetup;
}

- (id)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!context || ![EAGLContext setCurrentContext:context]) {
        return nil;
    }
    
    printGLString("Version", GL_VERSION);
	printGLString("Vendor", GL_VENDOR);
	printGLString("Renderer", GL_RENDERER);
	printGLString("Extensions", GL_EXTENSIONS);
    
	// create and use our program
	gProgram = createProgram(gVertexShader, gFragmentShader);
	if (!gProgram) {
		LOGE("Could not create program. \n");
		return nil;
	}
    glUseProgram(gProgram);
    
    // get the location of attributes in our shader
	gAttribPosition = glGetAttribLocation(gProgram, "a_position");
	gAttribTexCoord = glGetAttribLocation(gProgram, "a_texCoord");
    
    // get the location of uniforms in our shader
    gUniformTexY = glGetUniformLocation(gProgram, "u_texY");
	gUniformTexU = glGetUniformLocation(gProgram, "u_texU");
	gUniformTexV = glGetUniformLocation(gProgram, "u_texV");
    
	// can enable only once
	glEnableVertexAttribArray(gAttribPosition);
	glEnableVertexAttribArray(gAttribTexCoord);
    
	// set the value of uniforms (uniforms all have constant value)
	glUniform1i(gUniformTexY, 0);
	glUniform1i(gUniformTexU, 1);
	glUniform1i(gUniformTexV, 2);
    
	// generate and set parameters for the textures
    glEnable(GL_TEXTURE_2D);
    glGenTextures(3, gTexIds);
    for (int i = 0; i < 3; i++) {
    	glActiveTexture(GL_TEXTURE0 + i);
    	glBindTexture ( GL_TEXTURE_2D, gTexIds[i] );
    	glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
		glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
		glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
		glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    }
    
    // genarate frame and render buffers
    glGenFramebuffers(1, &defaultFramebuffer);
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    
    needSetup = 0;
    
    return self;
}

- (void) setRenderStateListener:(id<RenderStateListener>) lis
{
    listener = lis;
}

- (int) resizeFromLayer:(CAEAGLLayer *)layer
{
    // Allocate color buffer backing based on the current layer size
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        LOGI("failed to make complete framebuffer object %x \n", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return -1;
    }
    
    needSetup = 1;
    
    return 0;
}

- (void) render: (void*) data {
    
    struct VideoFrame *gVF = (struct VideoFrame*)data;
    
    if (needSetup) {
        
        [EAGLContext setCurrentContext:context];
        
		GLuint width = gVF->width;
		GLuint height = gVF->height;
        
		float aspect = (float)width / (float)height;
        
		if(aspect >= (float)backingWidth/(float)backingHeight) {
			// fill screen in width, and leave space in Y
			float scale = (float)backingWidth / (float) width;
			float maxY = ((float)height * scale) / (float) backingHeight;
			vertexPositions[1] = vertexPositions[4] = - maxY;
			vertexPositions[7] = vertexPositions[10] = maxY;
            
		} else {
			// fill screen in height, and leave space in X
			float scale = (float) backingHeight / (float) height;
			float maxX = ((float) width * scale) / (float) backingWidth;
			vertexPositions[0] = vertexPositions[6] = - maxX;
			vertexPositions[3] = vertexPositions[9] = maxX;
		}
        
		// modify the texture coordinates
		float texCoord = ((float)width) / gVF->linesize_y;
		textureCoords[2] = textureCoords[6] = texCoord;
        
		// set the value of attributes
		glVertexAttribPointer(gAttribPosition, 3, GL_FLOAT, 0, 0, vertexPositions);
		glVertexAttribPointer(gAttribTexCoord, 2, GL_FLOAT, 0, 0, textureCoords);
        
		glViewport(0, 0, backingWidth, backingHeight);
        
		LOGI("setup finished\n");
        
		needSetup = 0;
	}

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT);
    
    LOGD("before upload: %u (%f) \n", getms(), gVF->pts);
    
	// upload textures
	glActiveTexture(GL_TEXTURE0 + 0);
	glTexImage2D ( GL_TEXTURE_2D, 0, GL_LUMINANCE, gVF->linesize_y, gVF->height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, gVF->yuv_data[0]);
	glActiveTexture(GL_TEXTURE0 + 1);
	glTexImage2D ( GL_TEXTURE_2D, 0, GL_LUMINANCE, gVF->linesize_uv, gVF->height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, gVF->yuv_data[1]);
	glActiveTexture(GL_TEXTURE0 + 2);
	glTexImage2D ( GL_TEXTURE_2D, 0, GL_LUMINANCE, gVF->linesize_uv, gVF->height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, gVF->yuv_data[2]);
    
    [listener bufferDone];
    
    LOGD("after upload: %u (%f) \n", getms(), gVF->pts);
    
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    LOGD("after glDrawArrays: %u (%f) \n", getms(), gVF->pts);
    
    [context presentRenderbuffer:GL_RENDERBUFFER];
    
}



- (void)dealloc
{
    // delete buffers
    if (defaultFramebuffer) {
        glDeleteFramebuffers(1, &defaultFramebuffer);
        defaultFramebuffer = 0;
    }
    if (colorRenderbuffer) {
        glDeleteRenderbuffers(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }
    
    // tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    context = nil;
}

@end
