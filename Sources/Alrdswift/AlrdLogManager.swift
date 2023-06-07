//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/6/3.
//

import Foundation

open class AlrdLogger {
    
    ///define read type
    enum ReadType {
        case seekend
        case total
    }
    
    /// define log level
    internal enum LogLevel {
        case info(String?)
        case error(String?)
        case debug(String?)
        
        var baseDescription:String {
            switch self {
            case .info(_):
                return "info"
            case .error(_):
                return "error"
            case .debug(_):
                return "debug"
            }
        }
        
        var description:String {
            switch self {
            case .info(let log):
                return "\(baseDescription)\(log ?? "")"
            case .error(let log):
                return "\(baseDescription)\(log ?? "")"
            case .debug(let log):
                return "\(baseDescription)\(log ?? "")"
            }
        }
     
    }
    
    static let localLogPathKey = "localLogPath"
    
    /// get log path
    public func getAlrdLogPath(with groupId:String) throws -> String {
        guard let logParentUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
            throw AlrdError.nullValue("\(#function)\n\(#line)\n logPathUrl is nil")
        }
        let logPath = logParentUrl.path
        guard FileManager.default.fileExists(atPath: logPath) else {
            let contents = "FilePath create first time, please check tunnel"
            let contentsData = contents.data(using: .utf8)
            let createResult = FileManager.default.createFile(atPath: logPath, contents: contentsData)
            if createResult == false {
                throw AlrdError.nullValue(logFormat("create file at logPath failed"))
            }else {
                return logPath
            }
        }
        return logPath
    }
    
    /// read Data from filePath
    private func readDataFromSourcePath(_ sourcePath:String,_ readType:ReadType = .seekend,_ completionData:@escaping (Data?)->Void ) {
        let ioQueue = QueueType.custom(qos: .userInteractive, label: "com.alrd.alrdlogger").queue
        let fd = open(sourcePath, O_RDWR)
        let ioChannel = DispatchIO.init(type: .stream, fileDescriptor: fd, queue: ioQueue) { error in
            ///this error is always exit
            
        }
        let filesize = lseek(fd, 0, SEEK_END)
        var offset:off_t = 0
        switch readType {
        case .seekend:
            offset = filesize
            break
        case .total:
            offset = 0
            break
        }
        let buffersize = 2048
        let layout = MemoryLayout<UInt8>.alignment
        let rowBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: buffersize, alignment: layout)
        ioChannel.read(offset: offset, length: buffersize, queue: ioQueue) { done, data, error in
            if let data = data, data.count > 0 {
                data.copyBytes(to: rowBuffer, count: data.count)
                let formatData = Data.init(buffer: self.convertToUnsafeBufferPointer(from: rowBuffer))
                if done && error == 0{
                    ///file read finished or some bug
                    ioChannel.close()
                    completionData(nil)
                }
                completionData(formatData)
            }else {
                completionData(nil)
            }
            
        }
        
    }
    
    ///create local logPath to  record vpn launch
    /// -Return  a created local path
    public static func createOrLoadLocalLogFileToRecord(with groupId:String) throws -> String {
        guard let logParentUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
            throw AlrdError.nullValue(logFormat("logPathUrl is nil"))
        }
        let localPath = logParentUrl.path.appending("/localLog.log")
        guard FileManager.default.fileExists(atPath: localPath) == true else {
            /// create this file
            let createResult = FileManager.default.createFile(atPath: localPath, contents: nil)
            if createResult == false {
                throw AlrdError.cocoaError(logFormat("create localLog.log failed"))
            }
            return localPath
        }
        return localPath
    }
    
    /// write local vpn launch log to local log file
    internal static func writeDataToLocalLogFile(log content:String) throws -> Bool {
        guard let localLogPath = AlrdLogger.getLocalLogPath() else {
            throw AlrdError.nullValue(logFormat("local Path isn't exist"))
        }
        guard FileManager.default.isWritableFile(atPath: localLogPath) == true else {
            throw AlrdError.nullValue(logFormat("local Path isWritable == false"))
        }
        do {
            try content.write(toFile: localLogPath, atomically: true, encoding: .utf8)
        }catch let error {
            throw AlrdError.cocoaError(error.localizedDescription)
        }
        return true
    }
    
    ///  clean file
    public static func deleteLocalLogFile() throws -> Bool {
        if let localLogPath = AlrdLogger.getLocalLogPath() {
            guard FileManager.default.isDeletableFile(atPath: localLogPath) == true else {
                throw AlrdError.funcationError(logFormat("localLogPath is undeletable"))
            }
            do {
               try FileManager.default.removeItem(atPath: localLogPath)
            }catch let error {
                throw AlrdError.cocoaError(logFormat(error.localizedDescription))
            }
        }
        return true
    }
    
    /// log mode
    internal static func log(_ mode:AlrdInfoConfig.Level,_ type:AlrdLogger.LogLevel) {
        if mode.rawValue <= AlrdInfoConfig.level.rawValue {
            /// print this information
            switch type {
            case .info(let string):
                logInfo(info: string)
                break
            case .error(let string):
                logError(error: string)
                break
            case .debug(let string):
                logDebug(debug: string)
                break
            }
        }else {
            /// do nothing
        }
    }
    
    /// log error
    public static func logError(error description:String?) {
        NSLog("\(description)")
        let errorInfo = AlrdLogger.LogLevel.error(description).description
        do {
          let success = try AlrdLogger.writeDataToLocalLogFile(log:errorInfo)
        }catch let err {
            print(logFormat(err.localizedDescription))
        }
    }
    
    /// log info
    public static func logInfo(info description:String?) {
        NSLog("\(description)")
        let content = AlrdLogger.LogLevel.info(description).description
        do {
          let success = try AlrdLogger.writeDataToLocalLogFile(log:content)
        }catch let err {
            print(logFormat(err.localizedDescription))
        }
    }
    
    /// log debug
    public static func logDebug(debug description:String?) {
        NSLog("\(description)")
        let content = AlrdLogger.LogLevel.info(description).description
        do {
          let success = try AlrdLogger.writeDataToLocalLogFile(log:content)
        }catch let err {
            print(logFormat(err.localizedDescription))
        }
    }
}

extension AlrdLogger {
    ///UnsafeMutableRawBufferPointer -> UnsafeBufferPointer
    fileprivate func convertToUnsafeBufferPointer(from buffer: UnsafeMutableRawBufferPointer) -> UnsafeBufferPointer<UInt8> {
        let unsafeBufferPointer = UnsafeBufferPointer(start: buffer.baseAddress!.assumingMemoryBound(to: UInt8.self), count: buffer.count)
        return unsafeBufferPointer
    }
    
    /// store localLogPath
    public static func storeLocalPath(_ path:String) {
        UserDefaults.standard.set(path, forKey: localLogPathKey)
    }
    
    /// get localLogPath
    public static func getLocalLogPath() -> String? {
        return UserDefaults.standard.value(forKey: localLogPathKey) as? String
    }
    
    
}
