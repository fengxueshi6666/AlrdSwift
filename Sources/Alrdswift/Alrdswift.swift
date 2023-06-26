import NetworkExtension

// MARK: - define VPN status
public enum VPNStatus {
    case off
    case on
    case connecting
    case disconnecting
}

public class VPNManager {
    /// VPN  single manager
    public static let shared = VPNManager()
    
    private var tempConfigure = [String:Any]()
    private var userConfig:[String:Any]?
    internal var jsonString = "" // origin json string
    
    private init() {
        
    }
    
    deinit {
        
    }
    
    /// current provider is exist
    public func isProviderExist(_ completion:@escaping(Bool)->Void ) {
        guard AlrdLogger.getLocalLogPath()?.isEmpty == false else {
            print("AlrdInfoConfig regist failed")
            completion(false)
            return
        }
        AlrdLogger.log(.debug, .info(logFormat("")))
        var isExist = false
        NETunnelProviderManager.loadAllFromPreferences { providers, error in
            guard error == nil else {
                AlrdLogger.log(.error, .error(logFormat(AlrdError.cocoaError(error?.localizedDescription).description)))
                isExist = false
                completion(false)
                return
            }
            if let providers = providers {
                if let provider = providers.first {
                    AlrdLogger.log(.info, .info(logFormat("providers firt object is \(provider)")))
                    isExist = true
                }else {
                    //TODO: log provider is nil
                    
                }
            }else {
                AlrdLogger.log(.error, .error(logFormat(AlrdError.nullValue("proverders is nill").description)))
            }
            completion(isExist)
        }
        
    }
    
    /// VPN status callback
    public func getVPNStatus(callBack:@escaping (VPNStatus) ->Void) {
        NETunnelProviderManager.loadAllFromPreferences { providers, error in
            AlrdLogger.log(.debug, .info(logFormat("")))
            guard error == nil else {
                AlrdLogger.log(.error, .error(logFormat(AlrdError.cocoaError(error?.localizedDescription).description)))
                callBack(.off)
                return
            }
            if let providers = providers {
                if let provider = providers.first {
                    AlrdLogger.log(.info, .info(logFormat("providers firt object is \(provider)")))
                    self.connectionstatus(provider, callBack: callBack)
                }else {
                    //TODO: log provider is nil
                    callBack(.off)
                }
            }else {
                AlrdLogger.log(.error, .error(logFormat(AlrdError.nullValue("proverders is nill").description)))
                callBack(.off)
            }
        }
    }
    
    ///VPN notification push 
    public func listenVPNConnectionChanged(callBack:@escaping (VPNStatus)->Void) {
        AlrdLogger.log(.debug, .info(logFormat("")))
        NETunnelProviderManager.loadAllFromPreferences { providers, error in
            guard error == nil else {
                //TODO: log something error
                return
            }
            if let providers = providers {
                if let provider = providers.first {
                    let noti = AlrdNotification.connectionChangedNoti
                    let object = provider.connection
                    let queue = OperationQueue.main
                    postNoti(noti: noti, object: object, queue: queue) { _ in
                        self.connectionstatus(provider, callBack: callBack)
                    }
                    self.connectionstatus(provider, callBack: callBack)
                }else {
                }
            }else {

            }
        }
    }
    
    /// load configure
    /// - Parameters
    ///  - Parameter serverAddress: The VPN server. Depending on the protocol, may be an IP address, host name, or URL.
    ///  - Parameter localDescription:vpn descripption
    ///  - Parameter onDemand: It allows you to automatically establish VPN connections under certain conditions
   public func loadConfigureToCreateProvider(_ serverAddress:String = "0.0.0.0",_ localDescription:String = "Provider Example",_ onDemand:Bool = false) {
        tempConfigure["serverAddress"] = serverAddress
        tempConfigure["localDescription"] = localDescription
        tempConfigure["onDemand"] = onDemand
    }
    
    ///load user configure
   public func loadUserConfig(_ config:[String:Any]?) {
        userConfig = config
    }
    
    ///VPN connect callBack
   public func connect(callBack:@escaping(Error?)->Void) {
       AlrdLogger.log(.debug, .debug(logFormat("connect called begin")))
        NETunnelProviderManager.loadAllFromPreferences { providers, error in
            guard error == nil else {
                //TODO: log error
                AlrdLogger.log(.error, .error(logFormat(AlrdError.cocoaError(error?.localizedDescription).description)))
                return
            }
          
            var provider:NETunnelProviderManager!
            if (providers?.count == 0) {
                AlrdLogger.log(.info, .info(logFormat("no provider")))
                let newProvider = self.createProvider()
                provider = newProvider
            }else {
                provider = providers?.first
            }
            if (self.tempConfigure["onDemand"] != nil) == true && provider.isOnDemandEnabled == false {
                AlrdLogger.log(.debug, .debug(logFormat("user config tempConfigure['onDemand'] == true and set to true")))
                provider.isOnDemandEnabled = true
            }
            provider.isEnabled = true
            self.loadFullConfiguration(with: provider) {
                provider.saveToPreferences { error in
                    guard error == nil else {
                        AlrdLogger.log(.error, .error(logFormat(AlrdError.cocoaError(error?.localizedDescription).description)))
                        callBack(error)
                        return
                    }
                    provider.loadFromPreferences { error in
                        guard error == nil else {
                            AlrdLogger.log(.error, .error(logFormat(AlrdError.cocoaError(error?.localizedDescription).description)))
                            callBack(nil)
                            return
                        }
                        AlrdLogger.log(.info, .info("save success and load provider"))
                        callBack(nil)
                    }
                }
            }
            
        }
    }
    
    ///VPN disconnect callBack
   public func disconnect(callBack:@escaping()->Void) {
        NETunnelProviderManager.loadAllFromPreferences { providers, error in
            guard error == nil else {
                return
            }
            if let providers = providers {
                if let provider = providers.first {
                    AlrdLogger.log(.debug, .debug(logFormat("will setOnDemand to false")))
                    if provider.isOnDemandEnabled == true {
                        provider.isOnDemandEnabled = false
                        AlrdLogger.log(.debug, .debug(logFormat("OnDemand is false")))
                    }
                    provider.saveToPreferences { error in
                        guard error == nil else {
                            AlrdLogger.log(.error,.error(logFormat("\(error)")))
                            return
                        }
                        provider.connection.stopVPNTunnel()
                    }
                }
            }
        }
    }
    
    ///convert provider connection status to VPNStatus
    fileprivate func connectionstatus(_ provider:NETunnelProviderManager,  callBack:@escaping(VPNStatus)->Void) {
        let connectionStatus = provider.connection.status
        switch connectionStatus {
        case .connected:
            callBack(.on)
        case .connecting:
            callBack(.connecting)
        case .disconnecting:
            callBack(.disconnecting)
        case .disconnected:
            callBack(.off)
        default:
            callBack(.off)
        }
    }
    
    ///create provider to launch vpn
    fileprivate func createProvider() -> NETunnelProviderManager {
        AlrdLogger.log(.debug, .debug(logFormat("")))
        var rules = [NEOnDemandRule]()
        let rule = NEOnDemandRuleConnect()
        rule.interfaceTypeMatch = .any
        rules.append(rule)
        let provider = NETunnelProviderManager()
        provider.onDemandRules = rules
        if let onDemand = tempConfigure["onDemand"], onDemand as! Bool == true {
            provider.isOnDemandEnabled = true
        }
        let conf = NETunnelProviderProtocol()
        if let serverAddress = tempConfigure["serverAddress"] {
            conf.serverAddress = serverAddress as? String
        }
        provider.protocolConfiguration = conf
        if let localdescription = tempConfigure["serverAddress"] {
            provider.localizedDescription = localdescription as? String
        }
        AlrdLogger.log(.info, .info(logFormat(provider.localizedDescription)))
        return provider
    }
    
    /// update rule from user configuration
    fileprivate func updateRule(_ configure:[String:Any]?) -> String? {
        AlrdLogger.log(.debug, .debug(logFormat("")))
        AlrdLogger.log(.info, .info(logFormat(configure?.description)))
        guard let configure = configure else {
            //TODO: no configure
            AlrdLogger.log(.info, .info(logFormat("configure is nil")))
            return self.jsonString
        }
        /// match keys with local json file
        do {
            var jsonParent = try loadJsonString()
            configure.keys.forEach { key  in
                guard let contain = jsonParent?.keys.contains(key), contain == true else {
                    AlrdLogger.log(.error, .error(logFormat(AlrdError.nullValue("key \(key) is not contained in jsonParent").description)))
                    return
                }
                let updateValue = configure[key] as! String
                jsonParent?[key] = updateValue as AnyObject
            }
            let jsonData = try JSONSerialization.data(withJSONObject: jsonParent as Any)
            let jsonContent = String.init(data: jsonData, encoding: .utf8)
            return jsonContent
        }catch let error {
            //TODO: log the error
            AlrdLogger.log(.error, .error(logFormat(error.localizedDescription)))
            return nil
        }
        
    }
    
    /// load json from bundle
    fileprivate func loadJsonString() throws -> [String: AnyObject]? {
        do {
            guard let jsonData = self.jsonString.data(using: .utf8) else {
                throw AlrdError.nullValue("jsonData from jsonString is nil")
            }
            let object = try JSONSerialization.jsonObject(with: jsonData)
            AlrdLogger.log(.info, .info(logFormat("\(object)")))
            return object as? [String : AnyObject]
        }catch let error {
            throw AlrdError.cocoaError(error.localizedDescription)
        }
    }
    
    ///load full configuration
    fileprivate func loadFullConfiguration(with provider:NETunnelProviderManager,_ completion:@escaping()->Void) {
        let tpProtocol = provider.protocolConfiguration as! NETunnelProviderProtocol
        let jsonContent = updateRule(userConfig)
        let config = ["config":jsonContent]
        tpProtocol.providerConfiguration = config as [String : Any]
        provider.protocolConfiguration = tpProtocol
        completion()
    }
    
}
