//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/5/26.
//

import NetworkExtension
import ALRDTransitX
import ALRDTransitXProvider
@available(iOS 12.0, *)

public class AlrdNetworkTunnelProvider {
    
    ///net work listen monitor
    var nwPath: NWPathMonitor?
    var lastNIC: NWInterface?
    var lastBSSID: String?
    var tunnelUtil:AlrdTunnelUtil!
    
    public init() {
        
    }
    
    public func startTunnel(_ provider:NEPacketTunnelProvider,_ groupId:String,_ jsonContent:String, completionHandler: @escaping (Error?) -> Void ) {
        ///get configure from main progress
        guard let _ = (provider.protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration else {
            AlrdLogger.log(.error, .error(logFormat("Couldn't find alrd's config file")))
            exit(EXIT_FAILURE)
        }
        AlrdLogger.log(.debug, .debug("Networkextension start"))
        tunnelUtil = AlrdTunnelUtil(provider: provider)
        /// add start success notification
        NotificationCenter.default.addObserver(forName: AlrdNotification.alrdStartCallBack, object: nil, queue: OperationQueue.main) { notification in
            NSLog("beigin updateHttpProxy")
            AlrdLogger.log(.debug, .debug(logFormat("listen start success callback")))
            
            self.tunnelUtil.updateHTTPProxy(provider) { error in
                AlrdLogger.log(.info, .info(logFormat("updateHTTPProxy completion \(error.debugDescription)")))
                self.startNWPathWatcher()
            }
        }
        ///start listening network status, and will run alrd after network is satisfied
        nwPath = NWPathMonitor()
        nwPath?.pathUpdateHandler = { path in
            guard path.status == .satisfied else {
                return
            }
            AlrdLogger.log(.debug, .debug(logFormat("network is reachable")))
           let queueType = QueueType.custom(qos: .userInteractive, label: "com.alrd.alrdtunnel")
            queueType.queue.async {
                if let tunfd = getTunnelFD(provider) {
                    let jsonString = configTunnelWith(String(tunfd), groupId, jsonContent)
                    Transit.startAlrd(with: jsonString, callback: startCallback(code:info:), callback: runtimeCallback(code:info:))
                }else {
                    AlrdLogger.log(.error, .error(AlrdError.nullValue("tun fd is nil").description))
                }
            }
            self.nwPath?.cancel()
            AlrdLogger.log(.debug, .debug(logFormat("nwpath first cancel while alrd start")))
        }
        nwPath?.start(queue: QueueType.custom(qos: .default, label: "com.nwpath.tunnel").queue)
        AlrdLogger.log(.debug, .debug(logFormat("nwpath first start at queue \(QueueType.background.queue.description)")))
        provider.setTunnelNetworkSettings(nil) { error in
            NSLog("setTunnelNetworkSettings nil")
            guard error == nil else {
                AlrdLogger.log(.error, .error(logFormat(AlrdError.cocoaError(error?.localizedDescription).description)))
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }
    
}

extension AlrdNetworkTunnelProvider {
    @objc func startNWPathWatcher() {
        nwPath = NWPathMonitor()
        nwPath?.pathUpdateHandler = { path in
            guard path.status == .satisfied else {
                return
            }
            let currentInterface = path.availableInterfaces.first { path.usesInterfaceType($0.type) }
            guard self.lastNIC?.type != nil else {
                self.lastNIC = currentInterface
                return
            }
            guard self.lastNIC?.type == currentInterface?.type else {

                self.tunnelUtil.updateUpDns(self.tunnelUtil.provider)
                self.lastNIC = currentInterface
                return
            }
            switch currentInterface?.type {
            case .cellular:
                 self.handleNetworkChangedForCellular()
            case .wifi:
                 self.handleNetworkChangedForWIFI()
            case .wiredEthernet:
                 self.handleNetworkChangedForWiredEthernet()
            default:
                break
            }
            self.lastNIC = currentInterface
        }
        nwPath?.start(queue: DispatchQueue.global())
    }

    func handleNetworkChangedForWiredEthernet() {
    }

    func handleNetworkChangedForCellular() {
    }

    func handleNetworkChangedForWIFI() {
        if #available(iOSApplicationExtension 14.0, *) {
            if #available(iOS 14.0, *) {
                NEHotspotNetwork.fetchCurrent { current in
                    if current?.bssid != self.lastBSSID {
                        self.lastBSSID = current?.bssid
                        self.tunnelUtil.updateUpDns(self.tunnelUtil.provider)
                    }
                }
            } else {
                // Fallback on earlier versions
            }
            return
        }
        // Fallback on earlier versions
        let bssid = self.tunnelUtil.getWiFiBSSID()
        if bssid != lastBSSID {
            lastBSSID = bssid
            self.tunnelUtil.updateUpDns(self.tunnelUtil.provider)
        }
    }
}

///alrd callback function
func startCallback(code: Int32, info: UnsafePointer<Int8>!) {
    let nsinfo = String(cString: info)
    NSLog("code \(code),info\(nsinfo)")
    AlrdLogger.log(.info, .info(logFormat(nsinfo)))
    if code == 0 {
        NotificationCenter.default.post(Notification(name:AlrdNotification.alrdStartCallBack))
    }else {
        
    }
    
}

///alrd runtime callback
func runtimeCallback(code: Int32, info: UnsafePointer<Int8>!) {
    let nsinfo = String(cString: info)
    AlrdLogger.log(.info, .info(logFormat("code \(code) nsinfo \(nsinfo)")))
}
