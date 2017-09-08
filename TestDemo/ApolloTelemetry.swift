//
//  ApolloTelemetry.swift
//  Apollo
//
//  Created by Sara Itani Tue on 5/9/17.
//

import Crashlytics
import CocoaLumberjack

internal class EventName {
    static let ConnectCamera = "ConnectCamera"
    static let ErrorUSBManager = "ErrorUSBManager"
    static let CopyVideoToContentGallery = "CopyVideoToContentGallery"
    static let VideoMetadataInjection = "VideoMetadataInjection"
}

let USB360Errors : [Int32:String] = [
    -8000 : "The protocol version of Cam is incompatible with the Andriod SDK",
    -8001 : "Failed to send command",
    -8002 : "Data reception timeout",
    -8003 : "Mismatch between Ack and Request",
    -8004 : "SDK initialization failed or uninitialized",
    -8005 : "Parameter length of interface exceeds the maximum",
    -8006 : "Out of sequence that interface called"
]

internal class ApolloTelemetry {
    internal static func logCameraConnectedEvent(isCameraConnected: Bool, isCameraViewVisible: Bool, location: String) {
        let eventName = EventName.ConnectCamera;
        let eventAttributes: [String : Any] = [
            "success": isCameraConnected.description, // TRUE if connected, FALSE if disconnected
            "cameraViewVisible": isCameraViewVisible.description, // Camera view should not be visible
            "location": location // Class/method info
        ]

        logCustomEvent(eventName: eventName, eventAttributes: eventAttributes)
    }

    internal static func logErrorCodeFromUSBManager(errorCode: Int32, location: String = #function, caller: Any) {
        let eventName = EventName.ErrorUSBManager;
        let eventAttributes: [String : Any] = [
            "errorCode": errorCode,
            "errorMessage": USB360Errors[errorCode] ?? "Unknown Error",
            "location": "\(Mirror(reflecting: caller).subjectType).\(location)"
        ]
        
        logCustomEvent(eventName: eventName, eventAttributes: eventAttributes)
    }

    internal static func logCopyVideoToContentGalleryEvent(success: Bool, error : NSError? = nil) {
        logCustomEvent(
            eventName: EventName.CopyVideoToContentGallery,
            eventAttributes: [
                "success": success.description,
                "error": error?.description ?? ""
            ]
        )
    }

    internal static func logVideoMetadataInjectionEvent(success: Bool) {
        logCustomEvent(
            eventName: EventName.VideoMetadataInjection,
            eventAttributes: [
                "success": success.description,
            ]
        )
    }

    private static func logCustomEvent(eventName: String, eventAttributes: [String: Any]?) {
        Answers.logCustomEvent(withName: eventName, customAttributes: eventAttributes)
        DDLogInfo("[Telemetry Event] \(eventName): \(String(describing: eventAttributes?.description))")
    }
}
