//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/5/26.
//

import Foundation
import AlrdDns
import CFNetwork
public class Resolver {
    
   ///get local dns with CFNetwork
   public static func getLocalDNS() -> [String]? {
        let hostName = "baidu.com" // Replace with your desired hostname
        let hostRef = CFHostCreateWithName(nil, hostName as CFString)
       let hostValue:CFHost = hostRef.takeRetainedValue() 
       var success = DarwinBoolean(false)
        CFHostSetClient(hostValue, nil, nil)
        CFHostScheduleWithRunLoop(hostValue, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        CFHostStartInfoResolution(hostValue, .addresses, nil)

        var addresses: [String] = []

        if let addressesRef = CFHostGetAddressing(hostValue, &success), let addressesArr = addressesRef.takeUnretainedValue() as? [Data] {
            for addressData in addressesArr {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let addressRef = addressData as NSData
                let addr = addressRef.bytes.bindMemory(to: sockaddr.self, capacity: addressData.count)
                
                if getnameinfo(addr, socklen_t(addressData.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let addressString = String(cString: hostname)
                    addresses.append(addressString)
                }
            }
        }
        return addresses
    }

}


