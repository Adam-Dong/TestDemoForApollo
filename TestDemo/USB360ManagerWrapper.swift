//
//  USB360ManagerWrapper.swift
//  Apollo
//
//  Created by Vicente A. Rivera on 5/11/17.
//  Copyright © 2017 Vinasource company. All rights reserved.
//

import UIKit
import CocoaLumberjack

//  USB360ManagerWrapper
//
//  This class is used to wrap the USB360Manager class ans provides logging 
//  for all the actions to track what is happening in the library. We also 
//  track the connect and disconnect events and provide a way to display this
//  events as a toast in the root ui of the window.
//


class USB360ManagerWrapper
{
    var isObtainStream = false
    
    // Initializer to hook the events once the class is created.
    init(){
        setupCameraConectivity();
    }
    
    // Hooks the notification center events for the USBManager events.
    private func setupCameraConectivity () {
        DDLogInfo("[USB360Manager] observer for USB360 connection initalization")
        let notify = NotificationCenter.default
        notify.addObserver(self,
                           selector: #selector(cameraDidConnect(notification:)),
                           name: NSNotification.Name.USB360EAAccessoryDidConnect,
                           object: nil)
        notify.addObserver(self,
                           selector: #selector(cameraDidDisconnect(notification:)),
                           name: NSNotification.Name.USB360EAAccessoryDidDisconnect,
                           object: nil)
    }

    // Static accessor for the singleton class. We keep the same behavior as 
    // the original class with a singleton approach.
    static let sharedInstance: USB360ManagerWrapper = {
        let instance = USB360ManagerWrapper()
        return instance
    }()
    
    // Delegate used to process events on the UBSManager library.
    var delegate: Any!{
        set {
            DDLogInfo("[USB360Manager] Set a new delegate.");
            USB360Manager.shared().delegate = newValue;
        }
        get{
            return USB360Manager.shared().delegate;
        }
    }
    
    var audioCount: Int64{
        
        set{
        
            DDLogInfo("[USB360Manager] Set audioCount \(newValue)");
            USB360Manager.shared().audioCount = newValue;
        }
        
        get{
            return USB360Manager.shared().audioCount;
        }
    }
    
    var videoCount: Int64{
        set{
            
            DDLogInfo("[USB360Manager] Set videoCount \(newValue)");
            USB360Manager.shared().videoCount = newValue;
        }
        get{
            return USB360Manager.shared().videoCount;
        }
    }
    
    class func shared() -> (USB360ManagerWrapper!){
        return sharedInstance;
    }
    
    func initEASession() {
        DDLogInfo("[USB360Manager]  initEASession started.");
        USB360Manager.shared().initEASession();
        DDLogInfo("[USB360Manager]  initEASession ended.");
    }
    
    func initUSB360Handler(){
        DDLogInfo("[USB360Manager]  initUSB360Handler started.");
        USB360Manager.shared().initUSB360Handler();
        DDLogInfo("[USB360Manager]  initUSB360Handler ended.");
    }
    
    func destroyUSB360() -> Int32{
        DDLogInfo("[USB360Manager]  destroyUSB360 started.");
        let value = USB360Manager.shared().destroyUSB360();
        DDLogInfo("[USB360Manager]  destroyUSB360 ended.");
        logIfFailed(returnCode: value);
        return value;
    }

    func usbHandlerIsValid() -> Bool{
        DDLogInfo("[USB360Manager]  usbHandlerIsValid started.");
        let value = USB360Manager.shared().usbHandlerIsValid();
        DDLogInfo("[USB360Manager]  usbHandlerIsValid ended. Value = \(value)");
        return value;
    }
    
    func eaSessionIsValid() -> Bool{
        DDLogInfo("[USB360Manager]  eaSessionIsValid started.");
        let value = USB360Manager.shared().eaSessionIsValid();
        DDLogInfo("[USB360Manager]  eaSessionIsValid ended. Value = \(value)");
        return value;
    }

    func requestDeviceInfo() -> String!{
        DDLogInfo("[USB360Manager]  requestDeviceInfo started.");
        let value = USB360Manager.shared().requestDeviceInfo();
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  requestDeviceInfo ended. Value = \(String(describing: value))");
        return value;
    }

    func requestStreamInfo() -> String!{
        DDLogInfo("[USB360Manager]  requestStreamInfo started.");
        let value = USB360Manager.shared().requestStreamInfo();
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  requestStreamInfo ended. Value = \(String(describing: value))");
        return value;
    }
    
    func getLensParam() -> String!{
        
        DDLogInfo("[USB360Manager]  getLensParam started.");
        let value = USB360Manager.shared().getLensParam();
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  getLensParam ended. Value = \(String(describing: value))");
        return value;
    }
    
    func setLensParam(_ aLen: String!) -> Int32{
        DDLogInfo("[USB360Manager]  setLensParam started. aLen = \(aLen)");
        let value =  USB360Manager.shared().setLensParam(aLen);
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  setLensParam ended. Value = \(value)");
        logIfFailed(returnCode: value);
        return value;
    }
    
    func obtainStream() -> Int32{
        DDLogInfo("[USB360Manager]  obtainStream started.");
     
        let value =  USB360Manager.shared().obtainStream();
        if value == 0 {
            CameraManager.shared.stopHeartBeatTimer()
            isObtainStream = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                CameraManager.shared.stopTwoMinPowerOffTimer()
            }
        }

        DDLogInfo("[USB360Manager]  obtainStream ended. Value = \(value)");
        return value;
    }
    
    func releaseStream() -> Int32{
        DDLogInfo("[USB360Manager]  releaseStream started.");
        let value =  USB360Manager.shared().releaseStream();
        if value == 0 {
            isObtainStream = false
            DispatchQueue.main.async {
                CameraManager.shared.createTwoMinPowerOffTimer()
                CameraManager.shared.createHeartBeatTimerAndStart()
            }
        }
        DDLogInfo("[USB360Manager]  releaseStream ended. Value = \(value)");
        logIfFailed(returnCode: value);
        return value;
    }
    
    func setCameraIQ(_ iIQ: String!) -> Int32{
        DDLogInfo("[USB360Manager]  setCameraIQ started. iIQ = \(iIQ)");
        let value =  USB360Manager.shared().setCameraIQ(iIQ);
        DDLogInfo("[USB360Manager]  setCameraIQ ended. Value = \(value)");
        refreshTwoMinPowerOff()
        logIfFailed(returnCode: value);
        return value;
    }
    
    func getCameraIQ() -> String!{
        DDLogInfo("[USB360Manager]  getCameraIQ started.");
        let value = USB360Manager.shared().getCameraIQ();
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  getCameraIQ ended. Value = \(String(describing: value))");
        return value;
    }
    
    func getCameraMode() -> Int32{
        DDLogInfo("[USB360Manager]  getCameraMode started.");
        let value =  USB360Manager.shared().getCameraMode();
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  getCameraMode ended. Value = \(value)");
        return value;
    }
    
    func getCameraElectricityPercent() -> Int32{
        DDLogInfo("[USB360Manager]  getCameraElectricityPercent started.");
        let value =  USB360Manager.shared().getCameraElectricityPercent();
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  getCameraElectricityPercent ended. Value = \(value)");
        return value;
    }
    
    func getCameraPower() -> String!{
        DDLogInfo("[USB360Manager]  getCameraPower started.");
        let value =  USB360Manager.shared().getCameraPower();
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  getCameraPower ended. Value = \(String(describing: value))");
        return value;
    }
    
    func requestFWUpgrate(_ fwFile: String!, md5: String!) -> Int32{
        DDLogInfo("[USB360Manager]  requestFWUpgrate started. fwFile = \(fwFile!) md5 = \(md5!)");
        let value =  USB360Manager.shared().requestFWUpgrate(fwFile! , md5: md5!);
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  requestFWUpgrate ended. Value = \(value)");
        logIfFailed(returnCode: value);
        return value;
    }
    
    func requestUpdateProgress() -> Int32{
        DDLogInfo("[USB360Manager]  requestUpdateProgress started.");
        let value =  USB360Manager.shared().requestUpdateProgress();
        DDLogInfo("[USB360Manager]  requestUpdateProgress ended. Value = \(value)");
        return value;
    }
    
    func setCameraTime(_ formatTime: String!) -> Int32{
        DDLogInfo("[USB360Manager]  setCameraTime started. formatTime = \(formatTime)");
        let value =  USB360Manager.shared().setCameraTime(formatTime);
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  setCameraTime ended. Value = \(value)");
        logIfFailed(returnCode: value);
        return value;
    }
    
    func setCameraName(_ name: String!) -> Int32{
        DDLogInfo("[USB360Manager]  setCameraName started. name = \(name)");
        let value =  USB360Manager.shared().setCameraName(name);
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  setCameraName ended. Value = \(value)");
        logIfFailed(returnCode: value);
        return value;
    }
    
    func requestCameraPowerOff() -> Int32{
        DDLogInfo("[USB360Manager]  requestCameraPowerOff started.");
        let value =  USB360Manager.shared().requestCameraPowerOff();
        DDLogInfo("[USB360Manager]  requestCameraPowerOff ended. Value = \(value)");
        CameraManager.shared.stopHeartBeatTimer()
        CameraManager.shared.stopTwoMinPowerOffTimer()
        logIfFailed(returnCode: value);
        return value;
    }
    
    func requestCameraAutoPowerOffTime(_ times: String!) -> Int32{
        DDLogInfo("[USB360Manager]  requestCameraAutoPowerOffTime started. times = \(times)");
        let value =  USB360Manager.shared().requestCameraAutoPowerOffTime(times);
        DDLogInfo("[USB360Manager]  requestCameraAutoPowerOffTime ended. Value = \(value)");
        logIfFailed(returnCode: value);
        return value;
    }
    
    func getCameraPowerOffTime() -> String!{
        DDLogInfo("[USB360Manager]  getCameraPowerOffTime started.");
        let value = USB360Manager.shared().getCameraPowerOffTime();
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  getCameraPowerOffTime ended. Value = \(String(describing: value))");
        return value;
    }

    func requestCameraAutoPowerOffStart() -> Int32{
        DDLogInfo("[USB360Manager]  requestCameraAutoPowerOffStart started.");
        let value = USB360Manager.shared().requestCameraAutoPowerOffStart();
        DDLogInfo("[USB360Manager]  requestCameraAutoPowerOffStart ended. Value = \(value)");
        logIfFailed(returnCode: value);
        return value;
    }
    
    func requestCameraAutoPowerOffStop() -> Int32{
        DDLogInfo("[USB360Manager]  requestCameraAutoPowerOffStop started.");
        let value = USB360Manager.shared().requestCameraAutoPowerOffStop();
        DDLogInfo("[USB360Manager]  requestCameraAutoPowerOffStop ended. Value = \(value)");
        logIfFailed(returnCode: value);
        return value;
    }
    
    func requestSDKVersionInfo() -> String!{
        DDLogInfo("[USB360Manager]  requestSDKVersionInfo started.");
        let value = USB360Manager.shared().requestSDKVersionInfo();
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  requestSDKVersionInfo ended. Value = \(String(describing: value))");
        return value;
    }
    
    func  requestCameraHeartBeat() -> Int32 {
        DDLogInfo("[USB360Manager]  requestHeartBeat started.");
        let value = USB360Manager.shared().requestHeartBeat();
        DDLogInfo("[USB360Manager]  requestHeartBeat ended. Value = \(String(describing: value))");
        return value;
    }
    
    
    func requestSerialNumber() -> String!{
        DDLogInfo("[USB360Manager]  requestSerialNumber started.");
        let value = USB360Manager.shared().requestSerialNumber();
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  requestSerialNumber ended. Value = \(String(describing: value))");
        return value;
    }
    
    func  requestCaseSerialNumber() -> String!{
        DDLogInfo("[USB360Manager]  requestCaseSerialNumber started.");
        let value = USB360Manager.shared().getMCUSN()  ?? "";
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  requestCaseSerialNumber ended. Value = \(String(describing: value))");
        return value
    }
    
    func setSerialNumber(_ sn: String!) -> Int32{
        DDLogInfo("[USB360Manager]  setSerialNumber started. sn = \(sn)");
        let value = USB360Manager.shared().setSerialNumber(sn);
        refreshTwoMinPowerOff()
        DDLogInfo("[USB360Manager]  setSerialNumber ended. Value = \(value)");
        logIfFailed(returnCode: value);
        return value;
    }
    
    
    func setDefaultIQ() {
        let iqString = "{\"iso\":\(0),\"awb\":\(0),\"ev\":\(64),\"st\":\(0)}"
        setCameraIQ(iqString: iqString)
    }
    
    func setCameraIQWithNewValues(iso: String, awb: String, ev: String) {
        let iqString = "{\"iso\":\(iso),\"awb\":\(awb),\"ev\":\(ev),\"st\":\(0)}"
        setCameraIQ(iqString: iqString)
    }
    
    fileprivate func setCameraIQ( iqString : String) {
        DDLogInfo("[USB-API] Enter setCameraIQ function")
        DDLogDebug("[USB-API] Set cameraIQ with value \(iqString)")
        let success = USB360Manager.shared().setCameraIQ(iqString)
        if success != 0 {
            DDLogError("[USB-API] Failed to set cameraIQ with error code \(success)")
        } else {
            DDLogInfo("[USB-API] Set cameraIQ successfully.")
        }
        DDLogInfo("[USB-API] Exit setCameraIQ function")
        logIfFailed(returnCode: success);
    }
    
    func refreshTwoMinPowerOff() {
        if isObtainStream == false {
            CameraManager.shared.refreshTwoMinPowerOff()
        }
    }
    
    // notification handlers for the connect event we are not 
    // filtering the evnets all of them will be processed.
    @objc private func cameraDidConnect(notification: NSNotification) {
        DDLogInfo("[USB360Manager] cameraDidConnect event received.");
        // enable for visible message to debug.
        //self.showMessage(message: "cameraDidConnect event received.");
    }
    
    // notification handlers for the disconnect event we are not
    // filtering the evnets all of them will be processed.
    @objc private func cameraDidDisconnect(notification: NSNotification) {
        DDLogInfo("[USB360Manager] cameraDidDisconnect event received.");
        // enable for visible message to debug.
        //self.showMessage(message: "cameraDidDisconnect event received.");
    }
    
    // inspects the error code and sends telemetry event if its not Ok - 0
    func logIfFailed(returnCode:Int32 , location: String = #function){
        if(returnCode != 0){
            ApolloTelemetry.logErrorCodeFromUSBManager(errorCode: returnCode, location: location, caller: self);
        }
    }
    
    func showMessage(message: String){
    
        DispatchQueue.main.async {
            self.toastView(messsage: message, view: (UIApplication.shared.keyWindow!.rootViewController?.view)!);
        }
    }
    
    func toastView(messsage : String, view: UIView ){
        let toastLbl = UILabel(frame: CGRect(x: view.frame.size.width/2 - 150, y: view.frame.size.height-100, width: 300,  height : 35))
        toastLbl.backgroundColor = UIColor.black;
        toastLbl.textColor = UIColor.white;
        toastLbl.textAlignment = NSTextAlignment.center;
        view.addSubview(toastLbl)
        toastLbl.text = messsage
        toastLbl.alpha = 1.0
        toastLbl.layer.cornerRadius = 10;
        toastLbl.clipsToBounds  =  true
        UIView.animate(withDuration: 4.0, delay: 0.1, options: UIViewAnimationOptions.curveEaseOut, animations: {
            toastLbl.alpha = 0.0
        })
    }

}
