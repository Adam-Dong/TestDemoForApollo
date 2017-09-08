//
//  CameraManager.swift
//  Apollo
//
//  Created by Yoi Hibino on 2/17/17.
//  Copyright © 2017 Vinasource company. All rights reserved.
//

import UIKit

import CocoaLumberjack
import Crashlytics
import NSLogger

enum deviceConnectionState {
    case notConnected
    case caseIsConnected
    case cameraIsConnected
}

extension Notification.Name {
    static let ApolloCameraIsAvailable = Notification.Name(rawValue: "ApolloCameraIsAvailable")
    static let ApolloCameraIsNotAvailable = Notification.Name(rawValue: "ApolloCameraIsNotAvailable")
}


class CameraManager: NSObject {
    
    static let shared = CameraManager()
    fileprivate var cDevieInfo = ""
    fileprivate var firstLaunchCamera = true
    fileprivate var cameraSerialNumber = ""
    fileprivate var caseSerialTemp = ""
    var cameraFirmwareVersion = ""
    var caseFirmwareVersion = ""
    
    var deviceConnectionState: deviceConnectionState  = .notConnected
    // AI-686 fix bug: App can‘t receive connected Noti When plug camera autolaunch
    var DidReceiveCameraConnectedNotification : Bool = false
    
    var heartBeatTimer: Timer?
    var twoMinPowerOffTimer : Timer?
    var twoMincounter = 0
    var firmwareIsInstalling: Bool = false
    var isFirmwareUpdateViewController = false
    
    var caseSerialNumber : String {
        
        set {
            caseSerialTemp = newValue
        }
        get {
            // AI-686 bug: only plug case , tap version Information ,delay 2~3s show popView
            // fix: when camera not connected, not request caseSerialNumber.
            if caseSerialTemp == "" {
                // TODO ensure that this is running on the main thread
                // TODO Firmware bug - requestCaseSerialNumber currently takes 2 seconds when the camera is not connected.
                if deviceConnectionState == .cameraIsConnected {
                    caseSerialTemp = USB360ManagerWrapper.shared().requestCaseSerialNumber() ?? ""
                }
            }
            return caseSerialTemp
        }
    }
    
    override init() {
        super.init()
        setupCameraConectivity()
    }
    
    /**
     * Indicating of whether the camera has launched for first time or not
     *
     */
    
    var FirstLaunchCamera : Bool {
        
        get {
            return firstLaunchCamera
        }
        set {
            firstLaunchCamera = newValue
        }
        
    }
    
    var CameraSerialNumber : String {
        
        get {
            return cameraSerialNumber
        }
        set {
            cameraSerialNumber = newValue
        }
        
    }
    
    
    var cameraDeviceInfo : String {
        
        set {
            cDevieInfo = newValue
        }
        get {
            //[App's launch time] only
            if cDevieInfo == "" || cDevieInfo == ";;" {
                cDevieInfo = USB360ManagerWrapper.shared().requestDeviceInfo() ?? ""
            }
            return cDevieInfo
        }
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
        return nil
    }
    
    func setupCameraConectivity () {
        initSessionCamera()
        DDLogInfo("Register notification center to observer USB360 connection")
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
    
    func initSessionCamera() {
        
        if !USB360ManagerWrapper.shared().eaSessionIsValid() {
            DDLogInfo("[USB-API] Init EASession ")
            USB360ManagerWrapper.shared().initEASession()
        }
        
        if !USB360ManagerWrapper.shared().usbHandlerIsValid() {
            DDLogInfo("[USB-API] Init USB360")
            USB360ManagerWrapper.shared().initUSB360Handler()
        }
        
        if deviceConnectionState == .cameraIsConnected {
            initSomeInfoWhenCameraConnected()
        }
        
    }
    
    func isCameraAvailable () -> Bool {
        
        if deviceConnectionState == .cameraIsConnected && USB360ManagerWrapper.shared().usbHandlerIsValid() && USB360ManagerWrapper.shared().eaSessionIsValid() {
            return true
        }
        return false
        
    }
    
    
    func initSomeInfoWhenCameraConnected() {
        
        // For NSLogger Start
        Log(.App, .Info, "initSomeInfoWhenCameraConnected")
        
        let notify = NotificationCenter.default
        notify.post(name: NSNotification.Name.ApolloCameraIsAvailable, object: nil)
        
        let weakSelf = self
        // TODO - Verify this delay is still necessary.
        // We should not be using timers to detect when the camera is available.
        // Potentially related: https://helioglobal.atlassian.net/browse/AI-734
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
            
            Log(.Network, .Info, "initSomeInfoWhenCameraConnected firmwareIsInstalling:\(CameraManager.shared.firmwareIsInstalling)")
            if CameraManager.shared.firmwareIsInstalling == false {

                weakSelf.CameraSerialNumber = USB360ManagerWrapper.shared().requestSerialNumber() ?? ""
                weakSelf.caseSerialNumber = USB360ManagerWrapper.shared().requestCaseSerialNumber() ?? ""
        
                Crashlytics.sharedInstance().setObjectValue(weakSelf.CameraSerialNumber, forKey: "CameraSerialNumber")
                Crashlytics.sharedInstance().setObjectValue(weakSelf.caseSerialNumber, forKey: "CaseSerialNumber")
                Crashlytics.sharedInstance().setObjectValue(weakSelf.cameraFirmwareVersion, forKey: "CameraFirmwareVersion")
                Crashlytics.sharedInstance().setObjectValue(weakSelf.caseFirmwareVersion, forKey: "CaseFirmwareVersion")
                
                Log(.Network, .Info, "initSomeInfoWhenCameraConnected weakSelf.cameraDeviceInfo:\(weakSelf.cameraDeviceInfo)")
            }
        })
        
        self.createHeartBeatTimerAndStart()
        self.createTwoMinPowerOffTimer()
        
    }
    
    func createHeartBeatTimerAndStart() {
        
        Log(.App,.Info,"createHeartBeatTimerAndStart \(String(describing: heartBeatTimer))")
        if Apollo.isRequestCameraHeartBeat && Apollo.needToRequestCameraHeartBeatFWVersion.contains("2.3.000") {
            DispatchQueue.main.async {
                
                if self.heartBeatTimer == nil {
                    self.heartBeatTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(self.requestHeartBeatFromCamera), userInfo: nil, repeats: true)
                    self.heartBeatTimer?.fire()
                    Log(.App,.Info,"HeartBeatTimer fire")
                }
            }
        }
    }
    
    func stopHeartBeatTimer() {
        Log(.App,.Info,"stopHeartBeatTimer start heartBeatTimer = \(String(describing: heartBeatTimer))")
        DispatchQueue.main.async {
            
            if (self.heartBeatTimer != nil) {
                self.heartBeatTimer!.invalidate()
                self.heartBeatTimer = nil
                Log(.App,.Info,"HeartBeatTimer invalidate")
            }
        }
    }
    
    @objc func requestHeartBeatFromCamera() {
        
        Log(.App,.Info," requestCameraHeartBeat")
        
        if CameraManager.shared.isCameraAvailable() {
            
            let result = USB360ManagerWrapper.shared().requestCameraHeartBeat()
            
            if (result != 0) {
                Log(.App,.Info,"requestHeartBeat fail \(result)")
            }
            
        }
    }
    
    func createTwoMinPowerOffTimer() {
        if Apollo.isTwoMinPowerOff {
            if self.twoMinPowerOffTimer == nil {
                Log(.App,.Info,"createCountTimer start")
                self.twoMincounter = 0
                self.twoMinPowerOffTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.counterPlus), userInfo: nil, repeats: true)
            }
        }
    }
    
    func refreshTwoMinPowerOff() {
        twoMincounter = 0
    }
    
    func counterPlus() {
        twoMincounter += 1
        DDLogInfo("countAdd  + \(twoMincounter)")
        Log(.App,.Info,"countAdd \(twoMincounter)")
        if twoMincounter >= 120 && isFirmwareUpdateViewController == false {
            requestCameraPowerOff()
            twoMincounter = 0
        }
    }
    
    func stopTwoMinPowerOffTimer() {
        Log(.App,.Info,"stopTwoMinPowerOffTimer")
        if self.twoMinPowerOffTimer != nil {
            self.twoMinPowerOffTimer!.invalidate()
            self.twoMinPowerOffTimer = nil
            Log(.App,.Info,"twoMinCountTimer finsh")
        }
    }
    
    @objc func requestCameraPowerOff() {
        Log(.App,.Info,"requestCameraPowerOff")
        
        if CameraManager.shared.firmwareIsInstalling == false && CameraManager.shared.isCameraAvailable()
        {
            let  result  = USB360ManagerWrapper.shared().requestCameraPowerOff()
            Log(.App,.Info,"requestCameraPowerOff result:\(result)")
            
        }
        
    }
    
    @objc private func cameraDidConnect( notification: NSNotification) {
        // we need to handle this event all the time now becasue we are supporting background mode.
        DDLogInfo("[USB-API] USB connected")
        Log(.App,.Info,"cameraDidConnect Called")
        if checkAndUpdateDeviceConnectionState() == .cameraIsConnected {
            self.DidReceiveCameraConnectedNotification = true
            DDLogInfo("[USB-API] Camera connected")

            self.initSomeInfoWhenCameraConnected()
        }
    }

    func checkAndUpdateDeviceConnectionState() -> deviceConnectionState {
        // With the new MFI flow, we receive a notification every time either the
        // camera or case is connected. This function queries the device to see
        // what the current connection state is.
        if !USB360ManagerWrapper.shared().eaSessionIsValid() {
            DDLogInfo("[USB-API] Init EASession ")
            USB360ManagerWrapper.shared().initEASession()
        }
        
        if !USB360ManagerWrapper.shared().usbHandlerIsValid() {
            DDLogInfo("[USB-API] Init USB360")
            USB360ManagerWrapper.shared().initUSB360Handler()
        }
        
        // Ensure that requestDeviceInfo is being called on the main thread.
        var deviceInfo = ""
        if !Thread.isMainThread {
            Log(.App,.Info,"requestDeviceInfo in \(Thread.current)")
            DispatchQueue.main.sync {
                deviceInfo = USB360ManagerWrapper.shared().requestDeviceInfo() ?? ""
            }
        } else {
            Log(.App,.Info,"requestDeviceInfo in MainThread")
            deviceInfo = USB360ManagerWrapper.shared().requestDeviceInfo() ?? ""
        }
        
        let deviceInfoDic = convertToDictionary(text: deviceInfo)
        DDLogInfo("checkDeviceConnectionState  requestDeviceInfo = \(String(describing: deviceInfoDic))")
        Log(.App,.Info,"checkDeviceConnectionState  requestDeviceInfo = \(String(describing: deviceInfoDic))")
        self.cameraDeviceInfo = deviceInfo
        // TODO Parse json rather than string search
        if (deviceInfoDic?.keys.contains("camera"))! {
            self.deviceConnectionState = .cameraIsConnected
        } else if (deviceInfoDic?.keys.contains("case"))! {
            self.deviceConnectionState = .caseIsConnected
        } else {
            // We should never be in this state because this method should only
            // be called when we've received a camera connection or autolaunch event.
            DDLogInfo("checkAndUpdateDeviceConnectionState result: Not connected.")
            self.deviceConnectionState = .notConnected
        }
       
        return self.deviceConnectionState
    }
    
    @objc private func cameraDidDisconnect( notification: NSNotification) {
        // we need to handle this event all the time now becasue we are supporting background mode.
        DDLogInfo("[CameraManager] cameraDidDisconnect deviceConnectionState = \(deviceConnectionState)")
        Log(.App,.Info,"[CameraManager] cameraDidDisconnect deviceConnectionState = \(deviceConnectionState)")
        switch deviceConnectionState {
            case .caseIsConnected:
                self.deviceConnectionState = .notConnected
                destroyUSB360()
                return
            case .cameraIsConnected:
                DDLogInfo("[USB-API] USB disconnected.")
                Log(.App,.Info,"[USB-API] USB disconnected")
                self.deviceConnectionState = .caseIsConnected
                self.DidReceiveCameraConnectedNotification = false
                stopHeartBeatTimer()
                stopTwoMinPowerOffTimer()
                let notify = NotificationCenter.default
                notify.post(name: NSNotification.Name.ApolloCameraIsNotAvailable, object: nil)
                destroyUSB360()
            default:
                DDLogError("[CameraManager] cameraDidDisconnect error! \n deviceConnectionState = \(deviceConnectionState)")
                break
        }
    }
    
    func destroyUSB360 () {
        print(#function)
        // always destroy the USBConnection when the disconnect happened.
        // per Han BoBiao we need to call this api in all the disconnect events.
        USB360ManagerWrapper.shared().delegate = nil
        // https://helioglobal.atlassian.net/browse/AI-363
        let success: Int32 = USB360ManagerWrapper.shared().destroyUSB360()
        if success == 0 {
            DDLogInfo("[USB-API] Destroy USB 360 success.")
        } else {
            DDLogWarn("[USB-API] Failed to destroy USB360 with error code \(success)")
        }
    }

}
