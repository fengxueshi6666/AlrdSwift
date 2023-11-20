//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/7/5.
//

import Foundation
import Zip
//MARK: main progress interface
public class AlrdMainProgressProvider {
    
    /// regist with necessary parameters
    /// - Parameters:
    ///   - parameter logLevel: log output level
    ///   - parameter appGroup: app regist to communidate with networkextension
    ///   - parameter jsonString: acceleration profile with string format not file path
    /// - Returns: regist is true or false
    /// - Throws: if some paramters  == "" ,it will throw null error
    public static func regist(_ logLevel:AlrdInfoConfig.Level = .info,_ appGroup:String,_ jsonString:String,_ completion:@escaping(Bool,Error?)->Void) {
        do {
            let result = try AlrdInfoConfig.regist(logLevel:logLevel ,   appGroup: appGroup, jsonString: jsonString)
            completion(result,nil)
        } catch let error {
            completion(false,error)
        }
    }
    
    ///VPN Manager load user configure to replace jsonfile placeholder
    /// - Parameters:
    ///    - parameter config: A dict whose keys will  match json file and value will replace the value in json file
    public static func loadUserConfig(_ config:[String:Any]?) {
        VPNManager.shared.loadUserConfig(config)
    }
    
    /// load configure
    /// - Parameters
    ///  - Parameter serverAddress: The VPN server. Depending on the protocol, may be an IP address, host name, or URL.
    ///  - Parameter localDescription:vpn descripption
    ///  - Parameter onDemand: It allows you to automatically establish VPN connections under certain conditions
   public static func loadConfigureToCreateProvider(_ serverAddress:String = "0.0.0.0",_ localDescription:String = "Provider Example",_ onDemand:Bool = false) {
       VPNManager.shared.loadConfigureToCreateProvider(serverAddress,localDescription,onDemand)
    }
    
    /// NETunnelProviderManager.loadAllFromPreferences will callback three conditions:
    /// - error is not nil
    /// - providers is nil
    /// - provider is not nil
    /// if   not ensure when to listen vpn status changed , in order to make sure VPN status change callback , call this approach infront of listenVPNConnectionChanged
    public static func isProviderExist(_ completion:@escaping(Bool)->Void) {
       return VPNManager.shared.isProviderExist(completion)
    }
    
    /// VPN status changed callback
    public static func listenVPNConnectionChanged(callBack:@escaping (VPNStatus)->Void) {
        return VPNManager.shared.listenVPNConnectionChanged(callBack: callBack)
    }
    
    /// connect to VPN
    public static func connect(callBack:@escaping (Error?)->Void) {
        VPNManager.shared.connect(callBack: callBack)
    }
    
    /// connect to VPN
    public static func disConnect(callBack:@escaping ()->Void) {
        VPNManager.shared.disconnect(callBack: callBack)
    }
    
    //MARK: Certification status
    public struct CertificationStatus {
        /// bool download from local:127.0.0.1:12000
        public var download = false
        /// bool installed from Apple Setting
        public var installed = false
        /// bool verify the validity of the certificate
        public var verified = false
    }
    
    /// SSL Certifications status will be return
    public static func loadCertification(_ callBack:@escaping(_ certificationStatus:CertificationStatus?,_ error:Error?) -> Void) {
        do {
            try KeyChainManager.readMDMCertification({ isDownload, isInstalled, isVerified in
                var cStatus = CertificationStatus()
                cStatus.download = isDownload
                cStatus.installed = isInstalled
                cStatus.verified = isVerified
                callBack(cStatus,nil)
            })
        }catch let err {
            callBack(nil,err)
        }
    }
    
    /// get local log file
    public static func getLocalFile(_ callBack:@escaping(_ path:String?,_ error:Error?)->Void) {
        guard let localPath = AlrdLogger.getLocalLogPath(), localPath.isEmpty == false else {
            callBack(nil,AlrdError.nullValue(logFormat("localPath is empty")))
            return
        }
        callBack(localPath,nil)
    }
    
    /// get Alrd log File
    public static func getAlrdLogFile(_ callBack:@escaping(_ path:String?,_ error:Error?)->Void) {
        let groupID = AlrdInfoConfig.appGroup
        var path = ""
        do {
            path = try AlrdLogger.getAlrdLogPath(with: groupID)
        } catch let error {
            callBack(nil,error)
        }
        callBack(path,nil)
    }
    
    ///zip alrd log
    /// - Parameters
    ///  - Parameter zipPath:the path which will show the zip file
    /// - Returns
    ///  - Return zipPath : the path after zip operation
    ///  - Return error : the error while zip path
    public static func zipAlrdLog(_ zipPath:String, _ completion:@escaping(_ zipPath:String?,_ error:Error?)->Void) {
        getAlrdLogFile { path, error in
            guard error == nil else {
                completion(nil, error)
                return
            }
            guard let zipEntery = path else {
                completion(nil,nil)
                return
            }
            let fileUrl = URL(fileURLWithPath: zipEntery)
            let zipUrl = URL(fileURLWithPath: zipPath)
            do {
                try Zip.zipFiles(paths: [fileUrl], zipFilePath: zipUrl, password: nil) { progress in
                    if progress == 1 {
                        completion(zipPath,nil)
                    }
                }
                
            }catch let error {
                completion(nil,error)
            }
        }
    }
    
    ///zip local log
    /// - Parameters
    ///  - Parameter zipPath:the path which will show the zip file
    /// - Returns
    ///  - Return zipPath : the path after zip operation
    ///  - Return error : the error while zip path
    public static func zipLocalLog(_ zipPath:String, _ completion:@escaping(_ zipPath:String?,_ error:Error?)->Void) {
        getLocalFile{ path, error in
            guard error == nil else {
                completion(nil, error)
                return
            }
            guard let zipEntery = path else {
                completion(nil,nil)
                return
            }
            let fileUrl = URL(fileURLWithPath: zipEntery)
            let zipUrl = URL(fileURLWithPath: zipPath)
            do {
                try Zip.zipFiles(paths: [fileUrl], zipFilePath: zipUrl, password: nil) { progress in
                    if progress == 1 {
                        completion(zipPath,nil)
                    }
                }
                
            }catch let error {
                completion(nil,error)
            }
        }
    }
    
}
