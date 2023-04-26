// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.bean.response;

import android.os.Parcel;
import android.os.Parcelable;

import com.google.gson.annotations.SerializedName;
import com.volcengine.vertcdemo.core.net.rts.RTSBizResponse;
import com.volcengine.vertcdemo.liveshare.bean.Room;
import com.volcengine.vertcdemo.liveshare.bean.User;

import java.util.List;

public class JoinRoomResponse implements RTSBizResponse, Parcelable {

    @SerializedName("user_list")
    public List<User> users;
    @SerializedName("room")
    public Room room;

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeTypedList(this.users);
        dest.writeParcelable(this.room, flags);
    }

    public void readFromParcel(Parcel source) {
        this.users = source.createTypedArrayList(User.CREATOR);
        this.room = source.readParcelable(Room.class.getClassLoader());
    }

    public JoinRoomResponse() {
    }

    protected JoinRoomResponse(Parcel in) {
        this.users = in.createTypedArrayList(User.CREATOR);
        this.room = in.readParcelable(Room.class.getClassLoader());
    }

    public static final Parcelable.Creator<JoinRoomResponse> CREATOR = new Parcelable.Creator<JoinRoomResponse>() {
        @Override
        public JoinRoomResponse createFromParcel(Parcel source) {
            return new JoinRoomResponse(source);
        }

        @Override
        public JoinRoomResponse[] newArray(int size) {
            return new JoinRoomResponse[size];
        }
    };
}
