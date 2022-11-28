一起看直播是火山引擎实时音视频提供的一个开源示例项目。本文介绍如何快速跑通该示例项目，体验 RTC 一起看直播效果。

## 应用使用说明

使用该工程文件构建应用后，即可使用构建的应用进行一起看直播。
你和你的同事必须加入同一个房间，才能进行一起看直播。

## 前置条件

- [Xcode](https://developer.apple.com/download/all/?q=Xcode) 12.0+
	

- iOS 12.0+ 真机
	

- 有效的 [AppleID](http://appleid.apple.com/)
	

- 有效的 [火山引擎开发者账号](https://console.volcengine.com/auth/login)
	

- [CocoaPods](https://guides.cocoapods.org/using/getting-started.html#getting-started) 1.10.0+
	

## 操作步骤

### **步骤 1：获取 AppID 和 AppKey**

在火山引擎控制台->[应用管理](https://console.volcengine.com/rtc/listRTC)页面创建应用或使用已创建应用获取 AppID 和 AppAppKey

### **步骤 2：获取 AccessKeyID 和 SecretAccessKey**

在火山引擎控制台-> [密钥管理](https://console.volcengine.com/iam/keymanage/)页面获取 **AccessKeyID 和 SecretAccessKey**

### 步骤 3：构建工程

1. 打开终端窗口，进入 `LiveShareDemo/iOS/veRTC_Demo_iOS` 根目录

    <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_d3f101349124040d5cb3c7663b367e5b.png" width="500px" >
2. 执行 `pod install` 命令构建工程

    <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_62762043564f7f67ea64189cc636b14b.png" width="500px" >	
3. 进入 `LiveShareDemo/iOS/veRTC_Demo_iOS` 根目录，使用 Xcode 打开 `veRTC_Demo.xcworkspace`
    <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_e5d2cf81f47db67c34bfd12364c5f0c2.png" width="500px" >		

4. 在 Xcode 中打开 `Pods/Development Pods/Core/BuildConfig.h` 文件
    <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_5047a72b2a8f3340a1b302fe28b4d9e5.png" width="500px" >	


5. 填写 **LoginUrl** <br>
当前你可以使用 **https://common.rtc.volcvideo.com/rtc_demo_special/login** 作为测试服务器域名，仅提供跑通测试服务，无法保障正式需求。<br>
    <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_464d44a08f6505d311757e52c6e6d61b.png" width="500px" >

6. **填写 APPID、APPKey、AccessKeyID 和 SecretAccessKey**
使用在控制台获取的 **APPID、APPKey、AccessKeyID 和 SecretAccessKey** 填写到 `BuildConfig.h`文件的对应位置。<br>
    <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_6ac3d296dd1ffcf15f7e86a6420075fc.png" width="500px" >


### **步骤 4：配置开发者证书**

1. 将手机连接到电脑，在 `iOS Device` 选项中勾选您的 iOS 设备。<br>
    <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_8f337c258a7c0254f4dc3c121df5d9ab.png" width="500px" >

2. 登录 Apple ID。<br>
    2.1 选择 Xcode 页面左上角 **Xcode** > **Preferences**，或通过快捷键 **Command** + **,**  打开 Preferences。

    2.2 选择 **Accounts**，点击左下部 **+**，选择 Apple ID 进行账号登录。<br>
        <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_843711b3120f1a7279c02c3f7b9ade8b.png" width="500px" >


3. 配置开发者证书。
	

    3.1 单击 Xcode 左侧导航栏中的 `VeRTC_Demo` 项目，单击 `TARGETS` 下的 `VeRTC_Demo` 项目，选择 **Signing & Capabilities** > **Automatically manage signing** 自动生成证书 <br>
        <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_f825edf5354712773e6f17fae58873aa.png" width="500px" >


    3.2 在 **Team** 中选择 Personal Team。<br>
        <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_a247cb1ef6911c938aaff0c5936862c5.png" width="500px" >

    3.3 **修改 Bundle Identifier。** <br>
默认的 `vertc.veRTCDemo.ios` 已被注册， 将其修改为其他 Bundle ID，格式为 `vertc.xxx`。
       <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_807e4b3f245f8e48824f1f2245358599.png" width="500px" >
### **步骤 5 ：编译运行**

选择 **Product** > **Run**， 开始编译。编译成功后你的 iOS 设备上会出现新应用。若为免费苹果账号，需先在`设置->通用-> VPN与设备管理 -> 描述文件与设备管理`中信任开发者 APP。<br>
    <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_9774c48ccec2d07cfff59e3e11858034.png" width="500px" >

## 运行开始界面如下
 <img src="https://portal.volccdn.com/obj/volcfe/cloud-universal-doc/upload_b8adce92235730e8c6c35d03772fbabb.jpg" width="200px" >

