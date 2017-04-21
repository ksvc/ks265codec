package com.ksyun.media.ksy265codec.demo.ui;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.SurfaceHolder;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import com.ksyun.media.ksy265codec.demo.decoder.hevdecoder.NativeMediaPlayer;

/**
 * Created by sujia on 2017/3/27.
 */

public class DecoderFragment extends BaseFragment implements DecoderSettingsFragment.OnSettingsChangeListener,
        SurfaceHolder.Callback, NativeMediaPlayer.OnCompletionListener {
    private DecoderSettings mSettings = null;

    private static final String TAG = "DecoderFragment";
    private NativeMediaPlayer mPlayer;

    private boolean mPrepared = false;
    private int mWidth;
    private int mHeight;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = super.onCreateView(inflater, container, savedInstanceState);
        mSettings = Settings.getInstance().getDecoderSettings();

        updateUI();
        mSurfaceView.getHolder().addCallback(this);

        mPlayer = new NativeMediaPlayer();
        mPlayer.setCompletionListener(this);

        return view;
    }

    @Override
    protected void onSettingsClicked() {
        // Create an instance of the dialog fragment and show it
        DecoderSettingsFragment settingFragment = new DecoderSettingsFragment();
        settingFragment.setListener(this);
        settingFragment.show(this.getFragmentManager(), "setting dialog");
    }

    @Override
    public void onSettingsChanged(DecoderSettings settings) {
        this.mSettings = settings;
        updateUI();
    }

    @Override
    protected void onHelpClicked() {
        // Create an instance of the dialog fragment and show it
        HelpFragment settingFragment = new HelpFragment();
        settingFragment.setType(1);
        settingFragment.show(getFragmentManager(), "decode help dialog");
    }

    private void updateUI() {
        mTitleText.setText( mSettings.getDecoderName() + "解码器");
        if (mSettings.getFPS() != -1) {
            mSurfaceView.setVisibility(View.VISIBLE);
        } else {
            mSurfaceView.setVisibility(View.GONE);
        }
    }

    @Override
    protected void onStartClicked() {
        if (mSettings == null) {
            Toast.makeText(getContext(), "解码参数未配置",
                    Toast.LENGTH_SHORT).show();
            return;
        }

        if (mInputFilePath == null) {
            Toast.makeText(getContext(), "请选择输入文件",
                    Toast.LENGTH_SHORT).show();
            return;
        }

        mPrepared = false;

        mPlayer.init();
        int ret = mPlayer.setDataSource(mInputFilePath);
        if (ret != 0) {
            Toast.makeText(getContext(),
                    "请检查输入文件格式",
                    Toast.LENGTH_SHORT).show();
            return;
        }
        mPlayer.setDisplay(mSurfaceView.getHolder());
        mPlayer.setDisplaySize(mWidth, mHeight);

        // android maintains the preferences for us, so use directly
        int num = mSettings.getThreads();
        if ( 0 == num ) {
            int cores = Runtime.getRuntime().availableProcessors();
            if ( cores <= 1 )
                num = 1;
            else
                num = (cores < 4) ? (cores * 2) : 8;
            //Log.d(TAG, cores + " cores detected! use " + num + " threads.\n");
            Toast.makeText(getContext(),
                    "检测到手机为" + cores + "核! 使用 " + num + "个线程.\n",
                    Toast.LENGTH_SHORT).show();
        }

        //0: ksc265
        //1: lenthevcdec
        int decoderType = mSettings.decoderIndex == 0 ? 0 : 1;
        ret = mPlayer.prepare(decoderType, mSettings.getFPS() == -1 ? 1 : 0,
                num, mSettings.getFPS());
        if ( ret < 0 ) {
            Toast.makeText(getContext(),
                    "打开文件" + mInputFilePath + "失败，返回值: " + ret,
                    Toast.LENGTH_SHORT).show();
            return;
        } else {
            mPrepared = true;
        }

        if (mSettings.enableYUVOutput) {
            int dotIndex = mInputFilePath.lastIndexOf(".");
            String inputFileName = mInputFilePath.substring(0, dotIndex);
            mOutputFilePath = inputFileName + (mSettings.decoderIndex == 0 ? ".ksc" : ".lent" ) +".yuv";
            mPlayer.setOutput(mOutputFilePath);
        }

        toggleView(false);
        if (mPrepared) {
            mPlayer.start();
        }
    }

    //////////////////////////////////////////
    //implements SurfaceHolder.Callback
    @Override
    public void surfaceCreated(SurfaceHolder surfaceHolder) {
    }

    @Override
    public void surfaceChanged(SurfaceHolder surfaceHolder, int i, int i1, int i2) {
        mWidth = i1;
        mHeight = i2;
        if (mPlayer != null) {
            mPlayer.setDisplaySize(mWidth, mHeight);
        }
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder surfaceHolder) {
        mPlayer.stop();
    }

    // end of: implements SurfaceHolder.Callback
    /////////////////////////////////////////////

    @Override
    public void onCompletion(int frame_count) {
        updateInfo(frame_count);
        mPlayer.stop();
        toggleView(true);
    }

    private void updateInfo(int frame_num) {
        String last_info = mInfoText.getText().toString();
        String info;
        if (mSettings.enableYUVOutput) {
            info = String.format("解码器版本: %s \n" +
                            "\n" +
                            "\n" +
                            "解码参数: %s -b %s -o %s -threads %d \n" +
                            "\n" +
                            "\n" +
                            "分辨率: %d * %d \n" +
                            "线程数: %s \n" +
                            "解码时间: %.2f s\n" +
                            "解码帧数 %d \n" +
                            "解码速度 %.2f f/s\n" +
                            "渲染帧率 %s \n",
                    mPlayer.getVersion(), mSettings.getDecoderName(),
                    mInputFilePath, mOutputFilePath, mSettings.getThreads(),
                    mPlayer.getVideoWidth(), mPlayer.getVideoHeight(),
                    mSettings.getThreadsStr(), mPlayer.getDecodeTime(),
                    frame_num, mPlayer.getDecodeFPS(), mSettings.getFPSStr());
        } else {
            info = String.format("解码器版本: %s \n" +
                            "\n" +
                            "\n" +
                            "解码参数: %s -b %s -threads %d \n" +
                            "\n" +
                            "\n" +
                            "分辨率: %d * %d \n" +
                            "线程数: %s \n" +
                            "解码时间: %.2f s\n" +
                            "解码帧数 %d \n" +
                            "解码速度 %.2f f/s\n" +
                            "渲染帧率 %s \n",
                    mPlayer.getVersion(), mSettings.getDecoderName(),
                    mInputFilePath, mSettings.getThreads(),
                    mPlayer.getVideoWidth(), mPlayer.getVideoHeight(),
                    mSettings.getThreadsStr(), mPlayer.getDecodeTime(),
                    frame_num, mPlayer.getDecodeFPS(), mSettings.getFPSStr());
        }

        mInfoText.setText(info +
                "\n" +
                "\n" +
                last_info);
    }
}
