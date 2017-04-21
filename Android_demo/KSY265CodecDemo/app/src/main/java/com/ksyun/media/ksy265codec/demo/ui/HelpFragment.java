package com.ksyun.media.ksy265codec.demo.ui;

import android.app.Dialog;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.DialogFragment;
import android.support.v7.app.AlertDialog;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;

import com.ksyun.media.ksy265codec.demo.R;

/**
 * Created by sujia on 2017/3/28.
 */

public class HelpFragment extends DialogFragment {

    private int type;//0 encode, 1 decode

    public HelpFragment() {
    }

    public void setType(int type) {
        this.type = type;
    }

    @NonNull
    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState) {
        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        // Get the layout inflater
        LayoutInflater inflater = getActivity().getLayoutInflater();

        // Inflate and set the layout for the dialog
        // Pass null as the parent view because its going in the dialog layout
        View view = inflater.inflate(R.layout.help, null);

        if (type == 0) {
            TextView info = (TextView) view.findViewById(R.id.help_info);
            info.setText(R.string.encode_help_info);
        } else if (type == 1) {
            TextView info = (TextView) view.findViewById(R.id.help_info);
            info.setText(R.string.decode_help_info);
        }


        builder.setView(view);

        return builder.create();
    }
}
