//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/5/26.
//

import Foundation
import NetworkExtension

let logName = "alrd.log"
let alrdCachePath = "path_value"
let alrdLogPath = "log_path"
let alrdTunnelFD = "TUNFD"
let alrdUPDNS = "UPDNS"

///get tunnel fd
func getTunnelFD(_ provider:NEPacketTunnelProvider) -> Int32? {
    if #available(iOS 15, macOS 12, *) {
        var buf = [CChar](repeating: 0, count: Int(IFNAMSIZ))
        let utunPrefix = "utun".utf8CString.dropLast()
        return (0 ... 1024).first { (_ fd: Int32) -> Bool in
            var len = socklen_t(buf.count)
            return getsockopt(fd, 2 /* SYSPROTO_CONTROL */, 2, &buf, &len) == 0 && buf.starts(with: utunPrefix)
        }
    } else {
        return provider.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32
    }
}

///config tunnel to adapter json
func configTunnelWith(_ tunnelFD:String,_ groupId:String, _ jsonString:String) -> String {
    var jsonS = jsonString
    do {
        let cachePath = try AlrdTunnelFileCenter.loadOrCreateCachePath(with: groupId)
        let logPath = try configLogPath(groupId)
        jsonS = jsonS.replacingOccurrences(of: alrdCachePath, with: cachePath)
        jsonS = jsonS.replacingOccurrences(of: alrdLogPath, with: logPath)
    }catch let error {
        //TODO: log error
        AlrdLogger.log(.error, .error(logFormat("\(error.localizedDescription)")))
        return ""
    }
    var dnsarr = Resolver.getLocalDNSs()
    NSLog("init local dns \(dnsarr)")
    let regularDns = ["114.114.114.114","8.8.8.8","1.1.1.1", "114.114.115.115", "223.5.5.5", "223.6.6.6", "180.76.76.76", "8.8.4.4", "208.67.222.222"]
    dnsarr.append(contentsOf: regularDns)
    let dnsData = try! JSONSerialization.data(withJSONObject: dnsarr, options:[])
    let dnsStr = String.init(data: dnsData, encoding: .utf8)
    jsonS = jsonS.replacingOccurrences(of: alrdUPDNS, with:dnsStr!)
    jsonS = jsonS.replacingOccurrences(of: alrdTunnelFD, with: tunnelFD)
    
    return jsonS
}

func configLogPath(_ groupId:String) throws -> String {
    guard let logParentUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
        throw AlrdError.nullValue(logFormat("logParentUrl is nil"))
    }
    let logPath = logParentUrl.path.appending(logName)
    return logPath
}

