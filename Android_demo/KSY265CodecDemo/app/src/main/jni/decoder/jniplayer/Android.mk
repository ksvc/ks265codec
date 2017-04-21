LOCAL_PATH := $(call my-dir)
ARCH_ABI := $(TARGET_ARCH_ABI)
PREBUILT_PATH := $(LOCAL_PATH)/../../../../../../../prebuilt

#
# Prebuilt Shared library
#
include $(CLEAR_VARS)
LOCAL_MODULE	:= lenthevcdec
LOCAL_SRC_FILES	:= $(PREBUILT_PATH)/$(TARGET_ARCH_ABI)/liblenthevcdec.so
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE	:= qydecoder
LOCAL_SRC_FILES	:= $(PREBUILT_PATH)/$(TARGET_ARCH_ABI)/libqydecoder.a
include $(PREBUILT_STATIC_LIBRARY)

#
# jniplayer.so
#
include $(CLEAR_VARS)

ifeq ($(TARGET_ARCH_ABI), armeabi-v7a)
LENT_CFLAGS := -DARCH_ARM=1 -DHAVE_NEON=1
endif
ifeq ($(TARGET_ARCH_ABI), x86)
LENT_CFLAGS := -DARCH_X86_32=1
endif

LOCAL_C_INCLUDES += $(PREBUILT_PATH)/include

LOCAL_SRC_FILES := jniplayer.cpp jni_utils.cpp yuv2rgb565.cpp gl_renderer.cpp

LOCAL_LDLIBS := -llog -lz -ljnigraphics -lGLESv2

LOCAL_CFLAGS += $(LENT_CFLAGS)

LOCAL_SHARED_LIBRARIES := lenthevcdec

LOCAL_STATIC_LIBRARIES += qydecoder gnustl_static cpufeatures

LOCAL_MODULE := jniplayer

include $(BUILD_SHARED_LIBRARY)
