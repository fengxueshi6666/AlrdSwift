//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/5/26.
//

import Foundation

let cache = "/cache"

class AlrdTunnelFileCenter {
    
    /// if cache is not exist ,create ,otherwise return ; if create fault , alrd will also create cache file ,so also return the path
    static func loadOrCreateCachePath(with groupId:String) throws -> String {
        guard let cachePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
            throw AlrdError.nullValue("\(#function)\n\(#line)\n logPathUrl is nil")
        }
        let cachetotal = cachePath.path.appending("\(cache)")
        guard FileManager.default.fileExists(atPath: cachetotal) else {
            do {
                try FileManager.default.createDirectory(atPath: cachetotal, withIntermediateDirectories: true)
                return cachetotal
            }catch let error {
                //TODO: log the error
                ///alrd   create cache folder
                return cachetotal
            }
        }
        return cachetotal
    }
    
}
