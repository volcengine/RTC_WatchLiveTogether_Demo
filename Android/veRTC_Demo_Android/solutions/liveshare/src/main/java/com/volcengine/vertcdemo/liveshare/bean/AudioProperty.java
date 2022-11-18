package com.volcengine.vertcdemo.liveshare.bean;

public class AudioProperty {
    public String uid;
    public boolean isScreenStream;
    public boolean speaking;

    public AudioProperty(String uid, boolean isScreenStream, boolean speaking) {
        this.uid = uid;
        this.isScreenStream = isScreenStream;
        this.speaking = speaking;
    }

    public AudioProperty( boolean isScreenStream, boolean speaking) {
        this.isScreenStream = isScreenStream;
        this.speaking = speaking;
    }
}
