LOCAL_PATH := $(call my-dir)

PREBUILT_PATH := $(LOCAL_PATH)/../../../../../../prebuilt

include $(CLEAR_VARS)
LOCAL_MODULE := x264
LOCAL_SRC_FILES := $(PREBUILT_PATH)/$(TARGET_ARCH_ABI)/libx264.a
include $(PREBUILT_STATIC_LIBRARY)

ifneq ($(TARGET_ARCH_ABI),x86)
ifneq ($(TARGET_ARCH_ABI),x86_64)
include $(CLEAR_VARS)
LOCAL_MODULE := qy265
LOCAL_SRC_FILES := $(PREBUILT_PATH)/$(TARGET_ARCH_ABI)/libqyencoder.a
include $(PREBUILT_STATIC_LIBRARY)
endif
endif

include $(CLEAR_VARS)

LOCAL_LDLIBS += -llog

LOCAL_MODULE := native-lib

LOCAL_CONLYFLAGS += -std=c99

LOCAL_C_INCLUDES += $(PREBUILT_PATH)/include

LOCAL_SRC_FILES += encoderwrapper.c

LOCAL_STATIC_LIBRARIES += x264 qy265 gnustl_static cpufeatures

LOCAL_DISABLE_FATAL_LINKER_WARNINGS := true

include $(BUILD_SHARED_LIBRARY)

$(call import-module,android/cpufeatures)