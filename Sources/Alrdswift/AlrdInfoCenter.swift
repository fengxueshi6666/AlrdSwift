//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/5/25.
//

import Foundation
import Dispatch
import Network
import SwiftyPing

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
    
    public static var level:Level = .info
    public static var appGroup:String = ""
    
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
        
        tenthPing(times: 10)
        AlrdInfoConfig.level = logLevel
        KeyChainManager.appGroup = appGroup
        AlrdInfoConfig.appGroup = appGroup
        VPNManager.shared.jsonString = jsonString
        /// create localLogFile
        guard let localPath = AlrdLogger.getLocalLogPath(), localPath.isEmpty == false else {
            do {
               let logPath = try AlrdLogger.createOrLoadLocalLogFileToRecord(with: appGroup)
                AlrdLogger.storeLocalPath(logPath)
                print("logPath is \(logPath)")
            }catch let error {
                print("\(error)")
            }
            return true
        }
        
        do {
            let emptyString = ""
            try emptyString.write(toFile: localPath, atomically: true, encoding: .utf8)
        }catch let error {
            print("reset localfile to nil failed")
        }
        
        guard  AlrdLogger.getLocalLogPath()?.isEmpty == false else {
            throw AlrdError.funcationError(logFormat("get localLogPath failed"))
        }
        
        return true
    }
    
}

extension AlrdInfoConfig {
    
    static func tenthPing(times:Int) {
       let nwPath = NWPathMonitor()
       nwPath.pathUpdateHandler = { path in
           guard path.status != .satisfied else {
               return
           }
           guard times > 0 else {
               return
           }
           
           self.oncePing()
           Darwin.sleep(1)
           self.tenthPing(times: times - 1)
           
       }
       nwPath.start(queue: DispatchQueue.global())
   }
   
   static func oncePing() {
       let once = try? SwiftyPing(host: "www.baidu.com", configuration: PingConfiguration(), queue: DispatchQueue.global())
       once?.observer = { (response) in
           let duration = response.duration
           print(duration)
           once?.stopPinging(resetSequence: true)
       }
       once?.targetCount = 1
       try? once?.startPinging()
   }
}







