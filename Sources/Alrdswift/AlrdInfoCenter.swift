//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/5/25.
//

import Foundation
import Dispatch

//MARK: - noti enum
enum AlrdNotification {
    static let connectionChangedNoti = NSNotification.Name.NEVPNStatusDidChange
    static let alrdStartCallBack = NSNotification.Name("alrd.startCallback.toUpdateHttp")
}

//MARK: - queue enum
enum QueueType {
    case main
    case background
    case custom(qos: DispatchQoS, label: String)
    
    var queue: DispatchQueue {
        switch self {
        case .main:
            return DispatchQueue.main
        case .background:
            return DispatchQueue.global(qos: .background)
        case .custom(let qos, let label):
            return DispatchQueue(label: label, qos: qos)
        }
    }
    
    var notiQueue:OperationQueue {
        switch self {
        case .main:
            return OperationQueue.main
        case .background:
            let operate = OperationQueue()
            operate.qualityOfService = .background
            return operate
        case .custom(let qos, let label):
            let queue = DispatchQueue(label: label, qos: qos)
            let operate = OperationQueue()
            operate.name = label
            operate.underlyingQueue = queue
            return operate
        }
    }
    
}

//MARK: - noticenter
func postNoti(noti notiName:NSNotification.Name?, object:Any?, queue:OperationQueue?,callBack:@escaping(_ notification:Notification)->Void) {
    let center = NotificationCenter.default
    center.addObserver(forName: notiName, object: object, queue: queue) { notification in
        callBack(notification)
    }
}

//MARK: log Format from content
func logFormat(function: String = #function, line: Int = #line,_ content:String?) -> String {
    return "\(function)\n\(line):\(content ?? "")"
}

//MARK: SDK init config (must call at first time)
public class AlrdInfoConfig {
    /// log level
    /// Out put level from low to high
    public enum Level:Int {
        case error = 0
        case info  = 1
        case debug = 2
    }
    
    internal static var level:Level = .info
    
    /// regist with necessary parameters
    /// - Parameters:
    ///   - parameter logLevel: log output level
    ///   - parameter appGroup: app regist to communidate with networkextension
    ///   - parameter jsonString: acceleration profile with string format not file path
    /// - Returns: regist is true or false
    /// - Throws: if some paramters  == "" ,it will throw null error
    public static func regist(logLevel:Level = .info,appGroup:String,jsonString:String) throws -> Bool {
        guard appGroup.isEmpty == false else {
            throw AlrdError.nullValue(logFormat("appGroup cann't be null value"))
        }
        guard jsonString.isEmpty == false else {
            throw AlrdError.nullValue(logFormat("jsonString cann't be null value"))
        }
        
        AlrdInfoConfig.level = logLevel
        VPNManager.shared.jsonString = jsonString
        VPNManager.shared.getVPNStatus { status in
            guard status == .off else {
                return
            }
            /// create localLogFile
            guard let localPath = AlrdLogger.getLocalLogPath(), localPath.isEmpty == false else {
                do {
                   let logPath = try AlrdLogger.createOrLoadLocalLogFileToRecord(with: appGroup)
                    AlrdLogger.storeLocalPath(logPath)
                    print("logPath is \(logPath)")
                }catch let error {
                    print("\(error)")
                }
                return
            }
            do {
                let success = try AlrdLogger.deleteLocalLogFile()
                if success {
                    let logPath = try AlrdLogger.createOrLoadLocalLogFileToRecord(with: appGroup)
                    AlrdLogger.storeLocalPath(logPath)
                }
            }catch let error {
                print("\(error)")
            }
            
        }
        
        guard  AlrdLogger.getLocalLogPath()?.isEmpty == false else {
            throw AlrdError.funcationError(logFormat("get localLogPath failed"))
        }
        
        return true
    }
    
}







