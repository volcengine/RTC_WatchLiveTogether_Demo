// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.feature;

import android.annotation.SuppressLint;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.volcengine.vertcdemo.liveshare.R;

import java.util.ArrayList;
import java.util.List;

public class TextMessageAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private final List<String> mMessages = new ArrayList<>();

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_text_message, parent, false);
        return new TextMessageViewHolder(view);
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

