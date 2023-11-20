# Alrdswift

## Introduction

### Alrdswift is designed for simplifying proxy traffic

### it is componsed by three part :

* the first part is 'ALRDTransitXProvider', it provider a swift module to link alrd.a

* the second is code in main progress which can launch PackettunnelProvider

* the end is code in PackettunnelProvider which can set 
tunnel, and lauch alrd 

## Installation

* .package(url: "https://github.com/fengxueshi6666/Alrdswift.git", from: "0.0.17")

## Usage

``` 
// first setp: regist with gloab data
let file = Bundle.main.url(forResource: "jwt_i_automesh", withExtension: "json")
        
        if let file = file {
            do {
                let jsonString = try String(contentsOf: file)
                let groupId = "group.com.fengxueshi.TestForAlrd"
                /// create localLogFile
                let _ = try AlrdInfoConfig.regist(logLevel: .debug,  appGroup: groupId, jsonString: jsonString)
            }catch let error {
                print("error is \(error)")
            }
            print("file is \(file)")
           
        }else {
            
        }

// second: you can launch PackettunnelProvider 

/// userconfig - jsonfile content should be replaced
VPNManager.shared.loadUserConfig(nil)

/// create provider to show in Apple - setting - VPN if success
VPNManager.shared.loadConfigureToCreateProvider()

/// set connection or disconnection while user tap on toggle  button
func tapOnSwitch() {
        switch self.vpnStatus {
        case .off,.disconnecting:
            VPNManager.shared.connect { error in
                if self.isExist == false {
                    VPNManager.shared.listenVPNConnectionChanged { vpnStatus in
                        self.vpnStatus = vpnStatus
                        switch self.vpnStatus {
                        case .on, .connecting:
                            self.button.setOn(true, animated: true)
                        case .off, .disconnecting:
                            self.button.setOn(false, animated: true)
                        }
                    }
                }
            }
            break
        case .on,.connecting:
            VPNManager.shared.disconnect {
                
            }
            break
        }
    }
 ```

## Dependencies

* user need add swift package: https://github.com/krzyzanowskim/OpenSSL.git 

## Documents

TODO


