//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/6/6.
//

import Foundation
import ALRDTransitX
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

class AlrdTunnelUtil {
    
    private var lastDNSList:String = ""
    var provider:NEPacketTunnelProvider?
    
    convenience init(provider: NEPacketTunnelProvider) {
        self.init(provider: provider)
    }
    
    func updateUpDns(_ provider:NEPacketTunnelProvider) {
        provider.setTunnelNetworkSettings(nil, completionHandler: { _ in
            AlrdLogger.log(.debug, .debug(logFormat("Start update alrd-updns")))
            var dnsarr = Resolver.getLocalDNSs()
            let regularDns = ["114.114.114.114", "8.8.8.8", "1.1.1.1", "114.114.115.115", "223.5.5.5", "223.6.6.6", "180.76.76.76", "8.8.4.4", "208.67.222.222"]
            dnsarr.append(contentsOf: regularDns)
            var dns_list = ""
            for dns in dnsarr {
                dns_list.append("\(dns);")
            }
            dns_list.removeLast()
            if dns_list == self.lastDNSList {
                return provider.setTunnelNetworkSettings(self.initVPNSettings())
            }
            AlrdLogger.log(.info, .info(logFormat(dns_list)))
            
            Transit.updateDns(dns: dns_list)
            provider.setTunnelNetworkSettings(self.initVPNSettings())
            self.lastDNSList = dns_list
        })
    }
    
    // init VPN Settings
    func initVPNSettings() -> NEPacketTunnelNetworkSettings {
        let newSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "240.0.0.10")
        newSettings.ipv4Settings = NEIPv4Settings(addresses: ["240.0.0.1"], subnetMasks: ["255.255.255.0"])
        newSettings.ipv4Settings?.includedRoutes = [
            NEIPv4Route(destinationAddress: "198.18.0.0", subnetMask: "255.254.0.0"),
            NEIPv4Route(destinationAddress: "91.108.4.0", subnetMask: "255.255.252.0"),
            NEIPv4Route(destinationAddress: "91.108.8.0", subnetMask: "255.255.252.0"),
            NEIPv4Route(destinationAddress: "91.108.12.0", subnetMask: "255.255.252.0"),
            NEIPv4Route(destinationAddress: "91.108.16.0", subnetMask: "255.255.252.0"),
            NEIPv4Route(destinationAddress: "91.108.20.0", subnetMask: "255.255.252.0"),
            NEIPv4Route(destinationAddress: "91.108.56.0", subnetMask: "255.255.252.0"),
            NEIPv4Route(destinationAddress: "91.105.192.0", subnetMask: "255.255.254.0"),
            NEIPv4Route(destinationAddress: "149.154.160.0", subnetMask: "255.255.240.0"),
            NEIPv4Route(destinationAddress: "185.76.151.0", subnetMask: "255.255.255.0"),
        ]
        newSettings.dnsSettings = NEDNSSettings(servers: ["127.0.0.1"])
        newSettings.dnsSettings?.matchDomains = [""]
        newSettings.mtu = 1500
        return newSettings
    }

    @objc
    func updateHTTPProxy(_ provider:NEPacketTunnelProvider, completion:@escaping((Error?)->Void)) {
        let raw = Transit.getHttpAddr()
        let httpProxy = String(cString: raw!, encoding: .utf8)!
        AlrdLogger.log(.info, .info(logFormat(httpProxy)))
        if httpProxy.count == 0 {
            return
        }
        let arr = httpProxy.components(separatedBy: ":")

        guard let port = Int(String(arr[1])) else {
            AlrdLogger.log(.error, .error(AlrdError.funcationError("port is nil").description))
            return
        }
        let proxySettings = NEProxySettings()
        proxySettings.autoProxyConfigurationEnabled = true

        let pac_rule = """
        function FindProxyForURL(url, host)
        {
            var ip_addr = dnsResolve(host);
            if (isInNet(ip_addr, "198.18.0.0", "255.254.0.0")) {
                return "PROXY 127.0.0.1:\(port)";
            }
            return "DIRECT";
        }
        """
        proxySettings.proxyAutoConfigurationJavaScript = pac_rule
        proxySettings.excludeSimpleHostnames = true
        proxySettings.exceptionList = ["api.smoot.apple.com", "configuration.apple.com", "xp.apple.com", "smp-device-content.apple.com", "guzzoni.apple.com", "captive.apple.com", "*.ess.apple.com", "*.push.apple.com", "*.push-apple.com.akadns.net", ".push-apple.com.akadns.net"]
        let vpnSetting = initVPNSettings()
        vpnSetting.proxySettings = proxySettings
        provider.setTunnelNetworkSettings(vpnSetting) { error in
            guard error == nil else {
                AlrdLogger.log(.error, .error(AlrdError.cocoaError(error.debugDescription).description))
                completion(error)
                return
            }
            completion(nil)
        }
    }
    
    ///get wifi bssid
    func getWiFiBSSID() -> String? {
        guard let interfaceList = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }

        for interface in interfaceList {
            guard let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] else {
                continue
            }

            if let bssid = info[kCNNetworkInfoKeyBSSID as String] as? String {
                return bssid
            }
        }

        return nil
    }

}
