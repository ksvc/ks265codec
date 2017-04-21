package com.ksyun.media.ksy265codec.demo.ui;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

/**
 * Created by sujia on 2017/3/28.
 */

public class Settings {
    private static final String TAG = "settings";
    private static final boolean TRACE = true;

    private final String FILE_NAME = "ksy265codecdemo_settings";
    private SharedPreferences mSharedPreferences;
    private SharedPreferences.Editor mEditor;

    private static Settings sInstance;

    private EncoderSettings mEncoderSettings;
    private DecoderSettings mDecoderSettings;

    public static Settings getInstance() {
        if (sInstance == null) {
            synchronized (Settings.class) {
                if (sInstance == null) {
                    sInstance = new Settings();
                }
            }
        }

        return sInstance;
    }

    public void init(Context context) throws IllegalArgumentException {
        if (context == null) {
            throw new IllegalArgumentException("the context must not null");
        }

        if (mSharedPreferences == null) {
            mSharedPreferences = context.getSharedPreferences(FILE_NAME,
                    context.MODE_PRIVATE);
            mEditor = mSharedPreferences.edit();
        }
    }

    public EncoderSettings getEncoderSettings() {
        if (mSharedPreferences == null) {
            if (mEncoderSettings == null) {
                if(TRACE) {
                    Log.w(TAG, "please call init before call this function");
                }
                mEncoderSettings = new EncoderSettings();
                return mEncoderSettings;
            }
        }

        if (mEncoderSettings == null) {
            if(mSharedPreferences != null) {
                mEncoderSettings = new EncoderSettings(mSharedPreferences);
            } else {
                mEncoderSettings = new EncoderSettings();
            }
        }

        return mEncoderSettings;
    }

    public DecoderSettings getDecoderSettings() {
        if (mSharedPreferences == null) {
            if (mDecoderSettings == null) {
                if(TRACE) {
                    Log.w(TAG, "please call init before call this function");
                }
                mDecoderSettings = new DecoderSettings();
                return mDecoderSettings;
            }
        }

        if (mDecoderSettings == null) {
            if(mSharedPreferences != null) {
                mDecoderSettings = new DecoderSettings(mSharedPreferences);
            } else {
                mDecoderSettings = new DecoderSettings();
            }
        }
        return mDecoderSettings;
    }

    public void saveEncoderSettings(EncoderSettings settings) {
        if (mSharedPreferences == null) {
            return;
        }

        if (mEditor != null) {
            mEditor.putInt(EncoderSettings.ENCODER_SETTINGS_ENCODER, settings.encoderIndex);
            mEditor.putInt(EncoderSettings.ENCODER_SETTINGS_PROFILE, settings.profileIndex);
            mEditor.putInt(EncoderSettings.ENCODER_SETTINGS_DELAY, settings.delayIndex);
            mEditor.putString(EncoderSettings.ENCODER_SETTINGS_RESOLUTION, settings.resolution);
            mEditor.putInt(EncoderSettings.ENCODER_SETTINGS_RESOLUTION_IDX, settings.resIndex);
            mEditor.putString(EncoderSettings.ENCODER_SETTINGS_THREADS, settings.threads);
            mEditor.putString(EncoderSettings.ENCODER_SETTINGS_FPS, settings.fps);
            mEditor.putString(EncoderSettings.ENCODER_SETTINGS_BITRATE, settings.bitrate);

            mEditor.commit();
        }
    }

    public void saveDecoderSettings(DecoderSettings settings) {
        if (mSharedPreferences == null) {
            return;
        }

        if (mEditor != null) {
            mEditor.putInt(DecoderSettings.DECODER_SETTINGS_DECODER, settings.decoderIndex);
            mEditor.putInt(DecoderSettings.DECODER_SETTINGS_THREADS, settings.threadsIndex);
            mEditor.putInt(DecoderSettings.DECODER_SETTINGS_FPS, settings.fpsIndex);
            mEditor.putBoolean(DecoderSettings.DECODER_SETTINGS_OUTPUT, settings.enableYUVOutput);

            mEditor.commit();
        }
    }
}
