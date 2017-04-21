package com.ksyun.media.ksy265codec.demo.ui;

import android.app.Dialog;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.DialogFragment;
import android.support.v7.app.AlertDialog;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;

import com.ksyun.media.ksy265codec.demo.R;

/**
 * Created by sujia on 2017/3/28.
 */

public class EncoderSettingsFragment extends DialogFragment {
    private Spinner mEncoderSpinner;
    private Spinner mProfileSpinner;
    private Spinner mDelaySpinner;
    private EditText mResulutionEditTxt;
    private Spinner mResSpinner;
    private EditText mFpsEditTxt;
    private EditText mThreadsEditTxt;
    private EditText mBitrateEditTxt;
    private Button mButton;

    private EncoderSettings mSettings;

    public interface OnSettingsChangeListener {
        public void onSettingsChanged(EncoderSettings settings);
    }

    // Use this instance of the interface to deliver action events
    OnSettingsChangeListener mListener;

    public EncoderSettingsFragment() {
        mSettings = Settings.getInstance().getEncoderSettings();
    }

    public void setListener(OnSettingsChangeListener listener) {
        mListener = listener;
    }

    @NonNull
    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState) {
        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        // Get the layout inflater
        LayoutInflater inflater = getActivity().getLayoutInflater();

        // Inflate and set the layout for the dialog
        // Pass null as the parent view because its going in the dialog layout
        View view = inflater.inflate(R.layout.encoder_settings, null);

        mSettings = Settings.getInstance().getEncoderSettings();
        initView(view);

        builder.setView(view);

        return builder.create();
    }

    private void initView(View view) {
        ArrayAdapter<String> encodersAdapter = new ArrayAdapter<>(getContext(),
                android.R.layout.simple_spinner_item, EncoderSettings.Encoders);
        encodersAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mEncoderSpinner = (Spinner) view.findViewById(R.id.encoder_settings_encoder_spinner);
        mEncoderSpinner.setAdapter(encodersAdapter);
        if (mSettings.encoderIndex <= EncoderSettings.Encoders.length) {
            mEncoderSpinner.setSelection(mSettings.encoderIndex);
        }

        ArrayAdapter<String> profilesAdapter = new ArrayAdapter<>(getContext(),
                android.R.layout.simple_spinner_item, EncoderSettings.Profiles);
        profilesAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mProfileSpinner = (Spinner) view.findViewById(R.id.encoder_settings_profile_spinner);
        mProfileSpinner.setAdapter(profilesAdapter);
        if (mSettings.profileIndex <= EncoderSettings.Profiles.length) {
            mProfileSpinner.setSelection(mSettings.profileIndex);
        }

        ArrayAdapter<String> delayAdapter = new ArrayAdapter<>(getContext(),
                android.R.layout.simple_spinner_item, EncoderSettings.Delays);
        delayAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mDelaySpinner = (Spinner) view.findViewById(R.id.encoder_settings_delay_spinner);
        mDelaySpinner.setAdapter(delayAdapter);
        if (mSettings.delayIndex <= EncoderSettings.Delays.length) {
            mDelaySpinner.setSelection(mSettings.delayIndex);
        }

        mResulutionEditTxt = (EditText) view.findViewById(R.id.encoder_settings_resolution);
        mResulutionEditTxt.setText(mSettings.resolution);
        mResulutionEditTxt.setVisibility(View.VISIBLE);
        if (mSettings.resIndex == EncoderSettings.Resolutions.length -1) {
            mResulutionEditTxt.setVisibility(View.VISIBLE);
            mResulutionEditTxt.requestFocus();
        } else {
            mResulutionEditTxt.setVisibility(View.GONE);
        }

        ArrayAdapter<String> resAdapter  = new ArrayAdapter<>(getContext(),
                android.R.layout.simple_spinner_item, EncoderSettings.Resolutions);
        resAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mResSpinner = (Spinner) view.findViewById(R.id.encoder_settings_resolution_spinner);
        mResSpinner.setAdapter(resAdapter);
        if (mSettings.resIndex <= EncoderSettings.Resolutions.length -1) {
            mResSpinner.setSelection(mSettings.resIndex);
        }
        mResSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                if (mResulutionEditTxt == null) {
                    return;
                }

                if (position == EncoderSettings.Resolutions.length -1) {
                    mResulutionEditTxt.setVisibility(View.VISIBLE);
                    mResulutionEditTxt.requestFocus();
                } else {
                    mResulutionEditTxt.setVisibility(View.GONE);
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });

        mFpsEditTxt = (EditText) view.findViewById(R.id.encoder_settings_fps);
        mFpsEditTxt.setText(mSettings.fps);

        mThreadsEditTxt = (EditText) view.findViewById(R.id.encoder_settings_threads);
        mThreadsEditTxt.setText(mSettings.threads);

        mBitrateEditTxt = (EditText) view.findViewById(R.id.encoder_settings_bitrate);
        mBitrateEditTxt.setText(mSettings.bitrate);

        mButton = (Button) view.findViewById(R.id.encoder_settings_sure);
        mButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                mSettings.encoderIndex = mEncoderSpinner.getSelectedItemPosition();
                mSettings.profileIndex = mProfileSpinner.getSelectedItemPosition();
                mSettings.delayIndex = mDelaySpinner.getSelectedItemPosition();
                mSettings.resolution = mResulutionEditTxt.getText().toString();
                mSettings.resIndex = mResSpinner.getSelectedItemPosition();
                mSettings.fps = mFpsEditTxt.getText().toString();
                mSettings.threads = mThreadsEditTxt.getText().toString();
                mSettings.bitrate = mBitrateEditTxt.getText().toString();

                Settings.getInstance().saveEncoderSettings(mSettings);

                if (mListener != null) {
                    mListener.onSettingsChanged(mSettings);
                }

                dismiss();
            }
        });
    }
}
