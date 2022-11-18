package com.volcengine.vertcdemo.liveshare.feature;

import android.annotation.SuppressLint;
import android.content.Context;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.volcengine.vertcdemo.liveshare.R;
import com.volcengine.vertcdemo.liveshare.utils.Util;

import java.util.ArrayList;
import java.util.List;

public class TextMessageAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private final List<String> mMessages = new ArrayList<>();

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        Context context = parent.getContext();
        TextView messageTv = new TextView(context);
        messageTv.setGravity(Gravity.CENTER_VERTICAL | Gravity.START);
        messageTv.setPadding(Util.dp2px(4), Util.dp2px(2), Util.dp2px(4), Util.dp2px(2));
        messageTv.setTextSize(Util.sp2px(context, 4));
        messageTv.setTextColor(ContextCompat.getColor(context, R.color.white));
        messageTv.setBackground(ContextCompat.getDrawable(context, R.drawable.bg_text_message_item));
        return new TextMessageViewHolder(messageTv);
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        if (holder instanceof TextMessageViewHolder) {
            ((TextMessageViewHolder) holder).bind(mMessages.get(position));
        }
    }

    @Override
    public int getItemCount() {
        return mMessages.size();
    }

    /**
     * 加入一条信息
     */
    public void addTextMessage(String message) {
        if (TextUtils.isEmpty(message)) return;
        mMessages.add(message);
        notifyItemInserted(getItemCount() - 1);
    }

    /**
     * 清除所有信息
     */
    @SuppressLint("NotifyDataSetChanged")
    public void clearTextMessage() {
        mMessages.clear();
        notifyDataSetChanged();
    }

    private static class TextMessageViewHolder extends RecyclerView.ViewHolder {

        private final TextView mMessageTv;

        public TextMessageViewHolder(@NonNull View itemView) {
            super(itemView);
            mMessageTv = (TextView) itemView;
        }

        public void bind(String msg) {
            mMessageTv.setText(msg);
        }
    }
}

