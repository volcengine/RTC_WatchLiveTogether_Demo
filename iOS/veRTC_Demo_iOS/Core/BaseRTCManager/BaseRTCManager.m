//
//  BaseRTCManager.m
//  veRTC_Demo
//
//  Created by on 2021/12/16.
//  
//

#import "BaseRTCManager.h"

typedef NSString* RTMMessageType;
static RTMMessageType const RTMMessageTypeResponse = @"return";
static RTMMessageType const RTMMessageTypeNotice = @"inform";

@interface BaseRTCManager ()

@property (nonatomic, copy) void (^rtcLoginBlock)(BOOL result);
@property (nonatomic, copy) void (^rtcSetParamsBlock)(BOOL result);
@property (nonatomic, strong) NSMutableDictionary *listenerDic;
@property (nonatomic, strong) NSMutableDictionary *senderDic;
@property (nonatomic, strong) ByteRTCRoom *multiRTSRoom;

@end

@implementation BaseRTCManager

#pragma mark - Publish Action

- (void)connect:(NSString *)appID
       RTSToken:(NSString *)RTMToken
      serverUrl:(NSString *)serverUrl
      serverSig:(NSString *)serverSig
            bid:(NSString *)bid
          block:(void (^)(BOOL result))block {
    NSString *uid = [LocalUserComponent userModel].uid;
    if (IsEmptyStr(uid)) {
        if (block) {
            block(NO);
        }
        return;
    }
    if (self.rtcEngineKit) {
        [ByteRTCVideo destroyRTCVideo];
        self.rtcEngineKit = nil;
    }
    self.rtcEngineKit = [ByteRTCVideo createRTCVideo:appID delegate:self parameters:@{}];
    
    _businessId = bid;
    [self.rtcEngineKit setBusinessId:bid];
    [self configeRTCEngine];
    [self.rtcEngineKit login:RTMToken uid:uid];
    __weak __typeof(self) wself = self;
    self.rtcLoginBlock = ^(BOOL result) {
        wself.rtcLoginBlock = nil;
        if (result) {
            [wself.rtcEngineKit setServerParams:serverSig url:serverUrl];
        } else {
            wself.rtcSetParamsBlock = nil;
            dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
                if (block) {
                    block(result);
                }
            });
        }
    };
    self.rtcSetParamsBlock = ^(BOOL result) {
        wself.rtcSetParamsBlock = nil;
        dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
            if (block) {
                block(result);
            }
        });
    };
}

- (void)disconnect {
    [self.rtcEngineKit logout];
    [ByteRTCVideo destroyRTCVideo];
    self.rtcEngineKit = nil;
    self.rtcLoginBlock = nil;
    self.rtcSetParamsBlock = nil;
    self.rtcJoinRoomBlock = nil;
}

- (void)emitWithAck:(NSString *)event
               with:(NSDictionary *)item
              block:(RTCSendServerMessageBlock)block {
    if (IsEmptyStr(event)) {
        [self throwErrorAck:RTMStatusCodeInvalidArgument
                    message:@"??????EventName"
                      block:block];
        return;
    }
    NSString *appId = @"";
    NSString *roomId = @"";
    if ([item isKindOfClass:[NSDictionary class]]) {
        appId = item[@"app_id"];
        roomId = item[@"room_id"];
        if (IsEmptyStr(appId)) {
            [self throwErrorAck:RTMStatusCodeInvalidArgument
                        message:@"??????AppID"
                          block:block];
            return;
        }
    }
    NSString *wisd = [NetworkingTool getWisd];
    
    RTMRequestModel *requestModel = [[RTMRequestModel alloc] init];
    requestModel.eventName = event;
    requestModel.app_id = appId;
    requestModel.roomID = roomId;
    requestModel.userID = [LocalUserComponent userModel].uid;
    requestModel.requestID = [NetworkingTool MD5ForLower16Bate:wisd];
    requestModel.content = [item yy_modelToJSONString];
    requestModel.deviceID = [NetworkingTool getDeviceId];
    requestModel.requestBlock = block;
    
    NSString *json = [requestModel yy_modelToJSONString];
    requestModel.msgid = (NSInteger)[self.rtcEngineKit sendServerMessage:json];
    
    NSString *key = requestModel.requestID;
    [self.senderDic setValue:requestModel forKey:key];
    [self addLog:@"???????????????????????????" message:json];
}
           
- (void)onSceneListener:(NSString *)key
                  block:(RTCRoomMessageBlock)block {
    if (IsEmptyStr(key)) {
        return;
    }
    [self.listenerDic setValue:block forKey:key];
}

- (void)offSceneListener {
    [self.listenerDic removeAllObjects];
}

#pragma mark - Multi Room

- (void)joinMultiRTSRoomByToken:(NSString *)token
                      roomID:(NSString *)roomID
                      userID:(NSString *)userID {
    if (self.multiRTSRoom != nil) {
        [self leaveMultiRTSRoom];
    }
    self.multiRTSRoom = [self.rtcEngineKit createRTCRoom:roomID];
    [self.multiRTSRoom setRtcRoomDelegate:self];
    ByteRTCUserInfo *userInfo = [[ByteRTCUserInfo alloc] init];
    userInfo.userId = userID;

    ByteRTCRoomConfig *config = [[ByteRTCRoomConfig alloc] init];
    config.profile = ByteRTCRoomProfileInteractivePodcast;
    config.isAutoSubscribeAudio = NO;
    config.isAutoSubscribeVideo = NO;

    [self.multiRTSRoom joinRoomByToken:token userInfo:userInfo roomConfig:config];
}

- (void)leaveMultiRTSRoom {
    [self.multiRTSRoom leaveRoom];
    [self.multiRTSRoom destroy];
    self.multiRTSRoom = nil;
}

#pragma mark - Config

- (void)configeRTCEngine {
    // ??????????????????
    // need to be overridden by subclasses
}

#pragma mark - ByteRTCVideoDelegate

// ?????? RTS ????????????
// Receive RTS login result
- (void)rtcEngine:(ByteRTCVideo *)engine onLoginResult:(NSString *)uid errorCode:(ByteRTCLoginErrorCode)errorCode elapsed:(NSInteger)elapsed {
    if (self.rtcLoginBlock) {
        self.rtcLoginBlock((errorCode == ByteRTCLoginErrorCodeSuccess) ? YES : NO);
    }
}

// ???????????????????????????????????????
// Receive the business server parameter setting result
- (void)rtcEngine:(ByteRTCVideo *)engine onServerParamsSetResult:(NSInteger)errorCode {
    if (self.rtcSetParamsBlock) {
        self.rtcSetParamsBlock((errorCode == RTMStatusCodeSuccess) ? YES : NO);
    }
}

// ?????? RTC/RTS ??????????????????
// Receive RTC/RTS join room result
- (void)rtcRoom:(ByteRTCRoom *)rtcRoom onRoomStateChanged:(NSString *)roomId
        withUid:(NSString *)uid
          state:(NSInteger)state
      extraInfo:(NSString *)extraInfo {
    NSDictionary *dic = [self dictionaryWithJsonString:extraInfo];
    NSInteger errorCode = state;
    NSInteger joinType = -1;
    if ([dic isKindOfClass:[NSDictionary class]]) {
        NSString *joinTypeStr = [NSString stringWithFormat:@"%@", dic[@"join_type"]];
        joinType = joinTypeStr.integerValue;
    }
    
    dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
        if (self.rtcJoinRoomBlock) {
            self.rtcJoinRoomBlock(roomId, errorCode, joinType);
        }
        if (state == ByteRTCErrorCodeDuplicateLogin) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationLoginExpired object:@"logout"];
        }
    });
}

- (void)rtcEngine:(ByteRTCVideo *)engine onServerMessageSendResult:(int64_t)msgid error:(ByteRTCUserMessageSendResult)error message:(NSData *)message {
    if (error == ByteRTCUserMessageSendResultSuccess) {
        // ???????????????????????????????????????
        // Successfully sent, waiting for business callback information
    } else {
        // ????????????
        // Failed to send
        NSString *key = @"";
        for (RTMRequestModel *model in self.senderDic.allValues) {
            if (model.msgid == msgid) {
                key = model.requestID;
                [self throwErrorAck:RTMStatusCodeSendMessageFaild
                            message:[NetworkingTool messageFromResponseCode:RTMStatusCodeSendMessageFaild]
                              block:model.requestBlock];
                NSLog(@"[%@]-???????????????????????? %@ msgid %lld request_id %@ ErrorCode %ld", [self class], model.eventName, msgid, key, (long)error);
                break;
            }
        }
        if (NOEmptyStr(key)) {
            [self.senderDic removeObjectForKey:key];
        }
        
        if (error == ByteRTCUserMessageSendResultNotLogin) {
            dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationLoginExpired object:@"logout"];
            });
        }
    }
}

- (void)rtcEngine:(ByteRTCVideo *)engine onUserMessageReceivedOutsideRoom:(NSString *)uid message:(NSString *)message {

    [self dispatchMessageFrom:uid message:message];
    [self addLog:@"???????????????????????????????????????????????????" message:message];
}

- (void)rtcEngine:(ByteRTCVideo *)engine connectionChangedToState:(ByteRTCConnectionState)state {
    if (state == ByteRTCConnectionStateDisconnected) {
        for (RTMRequestModel *requestModel in self.senderDic.allValues) {
            if (requestModel.requestBlock) {
                RTMACKModel *ackModel = [[RTMACKModel alloc] init];
                ackModel.code = 400;
                ackModel.message = @"????????????????????????";
                dispatch_async(dispatch_get_main_queue(), ^{
                    requestModel.requestBlock(ackModel);
                });
            }
        }
        [self.senderDic removeAllObjects];
    }
}

#pragma mark - ByteRTCRoomDelegate

- (void)rtcRoom:(ByteRTCRoom *)rtcRoom onRoomMessageReceived:(NSString *)uid message:(NSString *)message {
    [self dispatchMessageFrom:uid message:message];
    [self addLog:@"??????????????????" message:message];
}

- (void)rtcRoom:(ByteRTCRoom *)rtcRoom onUserMessageReceived:(NSString *)uid message:(NSString *)message {
    [self dispatchMessageFrom:uid message:message];
    [self addLog:@"??????????????????" message:message];
}

#pragma mark - Private Action

- (void)dispatchMessageFrom:(NSString *)uid message:(NSString *)message {
    NSDictionary *dic = [NetworkingTool decodeJsonMessage:message];
    if (!dic || !dic.count) {
        return;
    }
    NSString *messageType = dic[@"message_type"];
    if ([messageType isKindOfClass:[NSString class]] &&
        [messageType isEqualToString:RTMMessageTypeResponse]) {
        [self receivedResponseFrom:uid object:dic];
        return;
    }
    
    if ([messageType isKindOfClass:[NSString class]] &&
        [messageType isEqualToString:RTMMessageTypeNotice]) {
        [self receivedNoticeFrom:uid object:dic];
        return;
    }
}

// ??????????????????????????????????????????????????????????????????
// Process the data result returned by the business server after receiving the client request
- (void)receivedResponseFrom:(NSString *)uid object:(NSDictionary *)object {
    RTMACKModel *ackModel = [RTMACKModel modelWithMessageData:object];
    if (IsEmptyStr(ackModel.requestID)) {
        return;
    }
    NSString *key = ackModel.requestID;
    RTMRequestModel *model = self.senderDic[key];
    if (model && [model isKindOfClass:[RTMRequestModel class]]) {
        if (model.requestBlock) {
            dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
                model.requestBlock(ackModel);
            });
        }
    }
    [self.senderDic removeObjectForKey:key];
}

// ???????????????????????????
// Receive server notification processing
- (void)receivedNoticeFrom:(NSString *)uid object:(NSDictionary *)object {
    RTMNoticeModel *noticeModel = [RTMNoticeModel yy_modelWithJSON:object];
    if (IsEmptyStr(noticeModel.eventName)) {
        return;
    }
    RTCRoomMessageBlock block = self.listenerDic[noticeModel.eventName];
    if (block) {
        dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
            block(noticeModel);
        });
    }
}

- (void)throwErrorAck:(NSInteger)code message:(NSString *)message
                block:(__nullable RTCSendServerMessageBlock)block {
    if (!block) {
        return;
    }
    RTMACKModel *ackModel = [[RTMACKModel alloc] init];
    ackModel.code = code;
    ackModel.message = message;
    dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
        block(ackModel);
    });
}

+ (NSString *_Nullable)getSdkVersion {
    return [ByteRTCVideo getSdkVersion];
}

#pragma mark - Getter

- (NSMutableDictionary *)listenerDic {
    if (!_listenerDic) {
        _listenerDic = [[NSMutableDictionary alloc] init];
    }
    return _listenerDic;
}

- (NSMutableDictionary *)senderDic {
    if (!_senderDic) {
        _senderDic = [[NSMutableDictionary alloc] init];
    }
    return _senderDic;
}

#pragma mark - Tool

- (void)addLog:(NSString *)key message:(NSString *)message {
    NSLog(@"[%@]-%@ %@", [self class], key, [NetworkingTool decodeJsonMessage:message]);
}

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
   if (jsonString == nil) {
       return nil;
   }

   NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
   NSError *err;
   NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                       options:NSJSONReadingMutableContainers
                                                         error:&err];
   if(err) {
       NSLog(@"json???????????????%@",err);
       return nil;
   }
   return dic;
}

@end
