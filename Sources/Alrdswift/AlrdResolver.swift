//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/5/26.
//

import Foundation
import AlrdDns
class Resolver {
    
    static func getLocalDNSs() ->[String] {
        let localDnss = get_localDns()
        var dnsArr: [String] = []
        var index = 0
        while let cString = localDnss?[index] {
            if let string = String(validatingUTF8: cString) {
                dnsArr.append(string)
            }
            index += 1
        }
        freeDNSServers(localDnss, Int32(dnsArr.count))
        return dnsArr
    }
    
}


