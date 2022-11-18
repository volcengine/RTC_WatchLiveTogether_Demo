package com.volcengine.vertcdemo.liveshare.bean;

import android.os.Parcel;
import android.os.Parcelable;

import androidx.annotation.IntDef;

import com.google.gson.annotations.SerializedName;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

public class Room implements Parcelable {

    public static final int SCENE_CHAT = 1;
    public static final int SCENE_SHARE = 2;

    @IntDef({SCENE_CHAT, SCENE_SHARE})
    @Retention(RetentionPolicy.SOURCE)
    public @interface SCENE {
    }

    public static final int SCREEN_ORIENTATION_LANDSCAPE = 1;
    public static final int SCREEN_ORIENTATION_PORTRAIT = 2;

    @IntDef({SCREEN_ORIENTATION_PORTRAIT, SCREEN_ORIENTATION_LANDSCAPE})
    @Retention(RetentionPolicy.SOURCE)
    public @interface SCREEN_ORIENTATION {
    }

    @SerializedName("app_id")
    public String appId;
    @SerializedName("room_id")
    public String roomId;
    @SerializedName("room_name")
    public String roomName;
    @SerializedName("host_user_id")
    public String hostUserId;
    @SerializedName("host_user_name")
    public String hostUserName;
    @SerializedName("status")
    public int status;
    @SerializedName("video_url")
    public String videoUrl;
    @SerializedName("compose")
    public int screenOrientation = SCREEN_ORIENTATION_PORTRAIT;
    @SerializedName("scene")
    @SCENE
    public int scene = SCENE_CHAT;
    @SerializedName("rtc_token")
    public String rtcToken;

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(this.appId);
        dest.writeString(this.roomId);
        dest.writeString(this.roomName);
        dest.writeString(this.hostUserId);
        dest.writeString(this.hostUserName);
        dest.writeInt(this.status);
        dest.writeString(this.videoUrl);
        dest.writeInt(this.screenOrientation);
        dest.writeInt(this.scene);
        dest.writeString(this.rtcToken);
    }

    public void readFromParcel(Parcel source) {
        this.appId = source.readString();
        this.roomId = source.readString();
        this.roomName = source.readString();
        this.hostUserId = source.readString();
        this.hostUserName = source.readString();
        this.status = source.readInt();
        this.videoUrl = source.readString();
        this.screenOrientation = source.readInt();
        this.scene = source.readInt();
        this.rtcToken = source.readString();
    }

    public Room() {
    }

    protected Room(Parcel in) {
        this.appId = in.readString();
        this.roomId = in.readString();
        this.roomName = in.readString();
        this.hostUserId = in.readString();
        this.hostUserName = in.readString();
        this.status = in.readInt();
        this.videoUrl = in.readString();
        this.screenOrientation = in.readInt();
        this.scene = in.readInt();
        this.rtcToken = in.readString();
    }

    public static final Parcelable.Creator<Room> CREATOR = new Parcelable.Creator<Room>() {
        @Override
        public Room createFromParcel(Parcel source) {
            return new Room(source);
        }

        @Override
        public Room[] newArray(int size) {
            return new Room[size];
        }
    };
}
