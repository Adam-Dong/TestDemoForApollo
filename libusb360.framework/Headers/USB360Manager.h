//
//  USB360Manager.h
//  libusb360
//
//  Created by hanbobiao on 16/11/3.
//  Copyright © 2016年 My Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import "LoggerClient.h"
#import "LoggerCommon.h"

#define VERSION "0.0.32 build 2017.08.25 15:16"

//LogMessageCompat(__VA_ARGS__)
extern NSString *const USB360EAAccessoryDidConnectNotification;
extern NSString *const USB360EAAccessoryDidDisconnectNotification;
extern NSString *const USB360EAAccessoryKey; // EAAccessory
extern NSString *const USB360EAAccessorySelectedKey; // EAAccessory

typedef enum {
    USB360ErrorCodeNoInitUSBHander = 1,
    USB360ErrorCodeUnknown = 2,
    USB360ErrorCodeParamNULL = 3,
}USB360ErrorCodeType;

typedef enum {
    ExposureShutterSpeedMode = 0,
    ExposureISOMode = 1,
    ExposureEvbiasMode
}USB360ExposureModeType;

typedef enum {
    CameraVideoMode = 0,
    CameraPhotoMode = 1,
}USB360CameraModeType;

typedef enum {
    WhiteBalanceAutoMode = 0,
    WhiteBalanceIncandescentLampMode = 1,
    WhiteBalanceCloudlessDayMode = 4,
    WhiteBalanceCloudyMode = 5,
    WhiteBalanceFlashLampMode = 8,
    WhiteBalanceFluorescentLampMode = 9,
    WhiteBalanceUnderWaterMode = 13,
    WhiteBalanceOutdoorsMode = 14
}USB360WhiteBalanceModeType;

@protocol USB360ManagerDelegate <NSObject>

@required
//get video/audio stream delegate function
- (void)receiveFrame:(int)channel data:(unsigned char*)data length:(int)lenght pts:(long)pts;

//get double click delegate function
- (void)receiveEvent:(int)type;

@end

@interface USB360Manager : NSObject

@property (nonatomic,retain) id delegate;
@property (nonatomic,assign) long long audioCount;
@property (nonatomic,assign) long long videoCount;

+ (USB360Manager *)sharedManager;
- (void)initEASession;
- (void)initUSB360Handler;
- (int)destroyUSB360;
- (BOOL)USBHandlerIsValid;
- (BOOL)EASessionIsValid;

//device name=Dev-Hero;SN number=1234567890;FW number=Apollo_V0.0.00.003
-(NSString*)requestDeviceInfo;

-(NSString*)requestStreamInfo;
-(NSString*)getLensParam;
-(int)setLensParam:(NSString *)aLen;
-(int)obtainStream;
-(int)releaseStream;
- (int)setCameraIQ:(NSString*)iIQ;
- (NSString*)getCameraIQ;
//- (int)setExposureMode:(USB360ExposureModeType)mode parameter:(USB360CameraModeType)parameter;
//- (int)setWhiteBalanceMode:(USB360WhiteBalanceModeType)mode parameter:(USB360CameraModeType)parameter;

//「0：Video；1:Photo」
- (int)getCameraMode;

- (int)getCameraElectricityPercent;
- (int)requestFWUpgrate:(NSString*)fwFile md5:(NSString*)md5;
- (int)requestUpdateProgress;

//获取系统时间设置给Camera，格式为（2016/01/28 19:00:00）
- (int)setCameraTime:(NSString*)formatTime;

- (int)setCameraName:(NSString*)name;

//「0:OK，其他:Fail」
- (int)requestCameraPowerOff;
//「0:OK，其他:Fail」
- (int)requestCameraAutoPowerOffTime:(NSString*)times;
//「0:OK，其他:Fail」
- (NSString *)getCameraPowerOffTime;

//「0:OK，其他:Fail」
- (int)requestCameraAutoPowerOffStart;

//「0:OK，其他:Fail」
- (int)requestCameraAutoPowerOffStop;

- (NSString*)requestSDKVersionInfo;
//get SN
- (NSString*)requestSerialNumber;
//set SN
- (int)setSerialNumber:(NSString*)sn;

- (int)setAppIsBackGround:(int)backgroundFlag;

- (int)getCameraTemperature;

- (NSString*)getCameraPower;

- (int)setCameraPower:(NSString*)power;

- (int)setCameraCircleCalib:(NSString*)calib;

- (NSString*)getCameraCircleCalib;

- (int)setCameraWB:(NSString*)wb;

- (NSString*)getCameraWB;

- (NSString*)getMCUSN;

- (int)getCameraLog:(NSString*)path;

//off:0,error:1,debug:2
- (int)setCameraLogLevel:(NSString*)level;

- (int)requestCameraRestoreFactory;

- (NSString*)getCameraPID;

- (int)setCameraPID:(NSString*)pID;

//- (int)sendCameraSwitchInterface;

- (int)requestStopReceivingUpdateFile;

- (int)requestQueryUpdateStatus;

- (int)requestHeartBeat;

- (NSString*)getCameraHWVersion;

- (int)setCameraHWVersion:(NSString*)hwVersion;

- (NSString*)getMCUHWVersion;

@end
