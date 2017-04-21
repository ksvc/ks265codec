package com.ksyun.media.ksy265codec.demo.ui;

import android.os.AsyncTask;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import com.ksyun.media.ksy265codec.demo.encoder.Encoder;

/**
 * Created by sujia on 2017/3/27.
 */

public class EncoderFragment extends BaseFragment implements EncoderSettingsFragment.OnSettingsChangeListener {

    private EncoderSettings mSettings = null;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = super.onCreateView(inflater, container, savedInstanceState);
        mSettings = Settings.getInstance().getEncoderSettings();
        mTitleText.setText( mSettings.getEncoderName() + "编码器");
        return view;
    }

    @Override
    protected void onSettingsClicked() {
        // Create an instance of the dialog fragment and show it
        EncoderSettingsFragment settingFragment = new EncoderSettingsFragment();
        settingFragment.setListener(this);
        settingFragment.show(this.getFragmentManager(), "encoder setting dialog");
    }

    @Override
    public void onSettingsChanged(EncoderSettings settings) {
        mSettings = settings;
        mTitleText.setText( mSettings.getEncoderName() + "编码器");
    }

    @Override
    protected void onHelpClicked() {
        // Create an instance of the dialog fragment and show it
        HelpFragment settingFragment = new HelpFragment();
        settingFragment.setType(0);
        settingFragment.show(getFragmentManager(), "encode help dialog");
    }

    @Override
    protected void onStartClicked() {
        if (mInputFilePath == null) {
            Toast.makeText(getContext(), "请选择yuv文件",
                    Toast.LENGTH_SHORT).show();
            return;
        }

        EncodeTask task = new EncodeTask();
        task.execute();
    }

    private class EncodeTask extends AsyncTask<Void, Void, Void> {

        private ProgressDialogFragment mProgressDialog;
        private Encoder mEncoder;

        @Override
        protected void onPreExecute() {
            mEncoder = new Encoder(mSettings);
            //Create progress dialog here and show it
            mProgressDialog = new ProgressDialogFragment();
            mProgressDialog.show(getFragmentManager(), "show progress dialog");

            toggleView(false);
        }

        @Override
        protected Void doInBackground(Void... params) {

            // Execute query here
            encodeYUV(mEncoder);
            return null;

        }

        @Override
        protected void onPostExecute(Void result) {
            super.onPostExecute(result);

            //update your listView adapter here
            //Dismiss your dialog
            toggleView(true);
            mProgressDialog.dismiss();
            updateInfo(mEncoder);
        }

    }


    private void encodeYUV(Encoder encoder) {
        if(encoder.open(mInputFilePath) < 0) {
            getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Toast.makeText(getContext(),
                            "打开yuv文件错误",
                            Toast.LENGTH_SHORT).show();
                }
            });
            return;
        }

        if(mSettings.getHeight() == 0 ||
                mSettings.getWidth() == 0 ||
                Integer.parseInt(mSettings.bitrate) <= 0 ||
                Integer.parseInt(mSettings.fps) <= 0) {
            getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Toast.makeText(getContext(),
                            "请检查编码参数设置",
                            Toast.LENGTH_SHORT).show();
                }
            });
            return;
        }

        if(encoder.encode() < 0) {
            getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Toast.makeText(getContext(),
                            "编码失败，请检查输入文件格式",
                            Toast.LENGTH_SHORT).show();
                }
            });
            return;
        }
    }

    private void updateInfo(Encoder encoder) {
        String last_info = mInfoText.getText().toString();

        String info;
        if (mSettings.getEncoderName().equals(EncoderSettings.Encoders[0])) {//KSC265
            info = String.format("编码器版本: %s \n " +
                            " \n" +
                            "编码参数: %s -i %s -preset %s -latency %s" +
                            " -wdt %d -hgt %d -fr %.2f -threads %d -br %d -b %s \n" +
                            " \n" +
                            "编码时间: %.2f s \n" +
                            "编码帧数: %d \n" +
                            "编码速度: %.2f f/s \n" +
                            "压缩比: %.2f \n" +
                            "PSNR: %.2f \n" +
                            "\n " +
                            "视频信息 \n " +
                            "码率: %.2f kbps \n" +
                            "分辨率: %s \n" +
                            "帧率: %.2f f/s\n" +
                            "文件总时长: %.2f s\n",
                    encoder.getVersion(), mSettings.getEncoderName(),
                    encoder.getInputFilePath(), mSettings.getProfile(), mSettings.getDelay(),
                    mSettings.getWidth(), mSettings.getHeight(), mSettings.getFps(),
                    mSettings.getThreads(), mSettings.getBitrate(), encoder.getOutputFilePath(),
                    encoder.getEncodeTime(), encoder.getEncodedFrameNum(),
                    encoder.getEncodeFPS(), encoder.getCompressRatio(),
                    encoder.getPSNR(),
                    encoder.getEncodeBitrate(), mSettings.getResolution(),
                    mSettings.getFps(), encoder.getDuration());
        } else {//x264
            String delayShow;
            if (mSettings.getDelay().equals(EncoderSettings.Delays[0])) {//zerolatency
                delayShow = "--bframes 0 --tune zerolatency";
            } else if(mSettings.getDelay().equals(EncoderSettings.Delays[1])) {//livestreaming
                delayShow = "--bframes 3";
            } else {//offline
                delayShow = "--bframes 7";
            }

            info = String.format("编码器版本: %s \n " +
                            " \n" +
                            "编码参数: %s -i %s --preset %s %s " +
                            "--input-res %dx%d --fps %.2f --threads %d --bitrate %d " +
                            "-o %s \n" +
                            " \n" +
                            "编码时间: %.2f s \n" +
                            "编码帧数: %d \n" +
                            "编码速度: %.2f f/s \n" +
                            "压缩比: %.2f \n" +
                            "PSNR: %.2f \n" +
                            "\n " +
                            "视频信息 \n" +
                            "码率: %.2f kbps \n" +
                            "分辨率: %s \n" +
                            "帧率: %.2f f/s\n" +
                            "文件总时长: %.2f s\n",
                    encoder.getVersion(), mSettings.getEncoderName(),
                    encoder.getInputFilePath(), mSettings.getProfile(), delayShow,
                    mSettings.getWidth(), mSettings.getHeight(), mSettings.getFps(),
                    mSettings.getThreads(), mSettings.getBitrate(), encoder.getOutputFilePath(),
                    encoder.getEncodeTime(), encoder.getEncodedFrameNum(),
                    encoder.getEncodeFPS(), encoder.getCompressRatio(),
                    encoder.getPSNR(),
                    encoder.getEncodeBitrate(), mSettings.getResolution(),
                    mSettings.getFps(), encoder.getDuration());
        }

        mInfoText.setText( info +
                "\n" +
                "\n" +
                "\n" +
                last_info);
    }
}
