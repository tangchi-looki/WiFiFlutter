import Flutter
import UIKit
import SystemConfiguration.CaptiveNetwork
import NetworkExtension

public class SwiftWifiIotPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "wifi_iot", binaryMessenger: registrar.messenger())
        let instance = SwiftWifiIotPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch (call.method) {
            /// Stand Alone
            case "loadWifiList":
                loadWifiList(result: result)
                break;
            case "forceWifiUsage":
                forceWifiUsage(call: call, result: result)
                break;
            case "isEnabled":
                isEnabled(result: result)
                break;
            case "setEnabled":
                setEnabled(call: call, result: result)
                break;
            case "findAndConnect": // OK
                findAndConnect(call: call, result: result)
                break;
            case "connect": // OK
                connect(call: call, result: result)
                break;
            case "isConnected": // OK
                isConnected(result: result)
                break;
            case "disconnect": // OK
                disconnect(result: result)
                break;
            case "getSSID":
                getSSID { (sSSID) in
                    result(sSSID)
                }
                break;
            case "getBSSID":
                getBSSID { (bSSID) in
                    result(bSSID)
                }
                break;
            case "getCurrentSignalStrength":
                getCurrentSignalStrength(result: result)
                break;
            case "getFrequency":
                getFrequency(result: result)
                break;
            case "getIP":
                getIP(result: result)
                break;
            case "removeWifiNetwork": // OK
                removeWifiNetwork(call: call, result: result)
                break;
            case "isRegisteredWifiNetwork":
                isRegisteredWifiNetwork(call: call, result: result)
                break;
            /// Access Point
            case "isWiFiAPEnabled":
                isWiFiAPEnabled(result: result)
                break;
            case "setWiFiAPEnabled":
                setWiFiAPEnabled(call: call, result: result)
                break;
            case "getWiFiAPState":
                getWiFiAPState(result: result)
                break;
            case "getClientList":
                getClientList(result: result)
                break;
            case "getWiFiAPSSID":
                getWiFiAPSSID(result: result)
                break;
            case "setWiFiAPSSID":
                setWiFiAPSSID(call: call, result: result)
                break;
            case "isSSIDHidden":
                isSSIDHidden(result: result)
                break;
            case "setSSIDHidden":
                setSSIDHidden(call: call, result: result)
                break;
            case "getWiFiAPPreSharedKey":
                getWiFiAPPreSharedKey(result: result)
                break;
            case "setWiFiAPPreSharedKey":
                setWiFiAPPreSharedKey(call: call, result: result)
                break;
            default:
                result(FlutterMethodNotImplemented);
                break;
        }
    }

    private func loadWifiList(result: FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    private func forceWifiUsage(call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments
        let useWifi = (arguments as! [String : Bool])["useWifi"]
        print("Forcing WiFi usage : %s", ((useWifi ?? false) ? "Use WiFi" : "Use 3G/4G Data"))
        if #available(iOS 14.0, *) {
            if(useWifi ?? false){
                // trigger access for local network
                triggerLocalNetworkPrivacyAlert();
            }
            result(true)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func connect(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let sSSID = (call.arguments as? [String : AnyObject])?["ssid"] as! String
        let _ = (call.arguments as? [String : AnyObject])?["bssid"] as? String? // not used
        let sPassword = (call.arguments as? [String : AnyObject])?["password"] as? String? ?? nil
        let bJoinOnce = (call.arguments as? [String : AnyObject])?["join_once"] as! Bool?
        let sSecurity = (call.arguments as? [String : AnyObject])?["security"] as! String?

        if #available(iOS 11.0, *) {
            let configuration = initHotspotConfiguration(ssid: sSSID, passphrase: sPassword, security: sSecurity)
            configuration.joinOnce = bJoinOnce ?? false

            NEHotspotConfigurationManager.shared.apply(configuration) { [weak self] (error) in
                guard let this = self else {
                    print("WiFi network not found")
                    result(FlutterError(code: "NETWORK_NOT_FOUND",
                                      message: "WiFi network not found",
                                      details: "Unable to locate network with SSID: \(sSSID)"))
                    return
                }
                this.getSSID { (connectedSSID) -> () in
                    if let error = error {
                        print("Connection error: \(error.localizedDescription)")

                        // Handle specific iOS error cases
                        let nsError = error as NSError
                        switch nsError.code {
                        case 1: // NEHotspotConfigurationErrorInvalid
                            result(FlutterError(code: "CONFIGURATION_FAILED",
                                              message: "Invalid network configuration",
                                              details: error.localizedDescription))
                        case 2: // NEHotspotConfigurationErrorInvalidSSID
                            result(FlutterError(code: "INVALID_SSID",
                                              message: "Invalid SSID",
                                              details: error.localizedDescription))
                        case 3: // NEHotspotConfigurationErrorInvalidWPAPassphrase
                            result(FlutterError(code: "AUTHENTICATION_FAILED",
                                              message: "Invalid WPA passphrase",
                                              details: error.localizedDescription))
                        case 4: // NEHotspotConfigurationErrorInvalidWEPPassphrase
                            result(FlutterError(code: "AUTHENTICATION_FAILED",
                                              message: "Invalid WEP passphrase",
                                              details: error.localizedDescription))
                        case 5: // NEHotspotConfigurationErrorUserDenied
                            result(FlutterError(code: "PERMISSION_DENIED",
                                              message: "User denied network access",
                                              details: error.localizedDescription))
                        case 6: // NEHotspotConfigurationErrorInternal
                            result(FlutterError(code: "CONFIGURATION_FAILED",
                                              message: "Internal configuration error",
                                              details: error.localizedDescription))
                        case 7: // NEHotspotConfigurationErrorPending
                            result(FlutterError(code: "CONNECTION_TIMEOUT",
                                              message: "Connection request is pending",
                                              details: error.localizedDescription))
                        case 8: // NEHotspotConfigurationErrorSystemConfiguration
                            result(FlutterError(code: "CONFIGURATION_FAILED",
                                              message: "System configuration error",
                                              details: error.localizedDescription))
                        case 9: // NEHotspotConfigurationErrorUnknown
                            result(FlutterError(code: "UNKNOWN_ERROR",
                                              message: "Unknown configuration error",
                                              details: error.localizedDescription))
                        case 10: // NEHotspotConfigurationErrorJoinOnceNotSupported
                            result(FlutterError(code: "CONFIGURATION_FAILED",
                                              message: "Join once not supported",
                                              details: error.localizedDescription))
                        case 11: // NEHotspotConfigurationErrorAlreadyAssociated
                            // This is actually a success case - already connected
                            print("Already connected to '\(connectedSSID ?? sSSID)'")
                            result(true)
                        case 12: // NEHotspotConfigurationErrorApplicationIsNotInForeground
                            result(FlutterError(code: "PERMISSION_DENIED",
                                              message: "Application is not in foreground",
                                              details: error.localizedDescription))
                        case 13: // NEHotspotConfigurationErrorInternalError
                            result(FlutterError(code: "CONFIGURATION_FAILED",
                                              message: "Internal system error",
                                              details: error.localizedDescription))
                        default:
                            // Check for common error messages as fallback
                            let errorMessage = error.localizedDescription.lowercased()
                            if errorMessage.contains("already associated") {
                                print("Already connected to '\(connectedSSID ?? sSSID)'")
                                result(true)
                            } else if errorMessage.contains("password") || errorMessage.contains("passphrase") {
                                result(FlutterError(code: "AUTHENTICATION_FAILED",
                                                  message: "Authentication failed - incorrect password",
                                                  details: error.localizedDescription))
                            } else if errorMessage.contains("timeout") {
                                result(FlutterError(code: "CONNECTION_TIMEOUT",
                                                  message: "Connection timeout",
                                                  details: error.localizedDescription))
                            } else if errorMessage.contains("denied") {
                                result(FlutterError(code: "PERMISSION_DENIED",
                                                  message: "Permission denied",
                                                  details: error.localizedDescription))
                            } else {
                                result(FlutterError(code: "UNKNOWN_ERROR",
                                                  message: "Connection failed",
                                                  details: error.localizedDescription))
                            }
                        }
                    } else if let connectedSSID = connectedSSID {
                        print("Connected to " + connectedSSID)
                        // Emit result of [isConnected] by checking if targetSSID is the same as connectedSSID.
                        if sSSID == connectedSSID {
                            result(true)
                        } else {
                            result(FlutterError(code: "NETWORK_UNAVAILABLE",
                                              message: "Connected to different network",
                                              details: "Expected: \(sSSID), Connected to: \(connectedSSID)"))
                        }
                    } else {
                        print("WiFi network not found")
                        result(FlutterError(code: "NETWORK_NOT_FOUND",
                                          message: "WiFi network not found after connection attempt",
                                          details: "Unable to verify connection to SSID: \(sSSID)"))
                    }
                }
            }
        } else {
            print("iOS version not supported")
            result(FlutterError(code: "CONFIGURATION_FAILED",
                              message: "iOS version not supported",
                              details: "NEHotspotConfiguration requires iOS 11.0 or later"))
            return
        }
    }

    private func findAndConnect(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    @available(iOS 11.0, *)
    private func initHotspotConfiguration(ssid: String, passphrase: String?, security: String? = nil) -> NEHotspotConfiguration {
        switch security?.uppercased() {
            case "WPA":
                return NEHotspotConfiguration.init(ssid: ssid, passphrase: passphrase!, isWEP: false)
            case "WEP":
                return NEHotspotConfiguration.init(ssid: ssid, passphrase: passphrase!, isWEP: true)
            default:
                return NEHotspotConfiguration.init(ssid: ssid)
        }
    }

    private func isEnabled(result: @escaping FlutterResult) {
        // For now..
        getSSID { (sSSID) in
            if (sSSID != nil) {
                result(true)
            } else {
                result(nil)
            }
        }
    }

    private func setEnabled(call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments
        let state = (arguments as! [String : Bool])["state"]
        if (state != nil) {
            print("Setting WiFi Enable : \(((state ?? false) ? "enable" : "disable"))")
            result(FlutterMethodNotImplemented)
        } else {
            result(nil)
        }
    }

    private func isConnected(result: @escaping FlutterResult) {
        // For now..
        getSSID { (sSSID) in
            if (sSSID != nil) {
                result(true)
            } else {
                result(false)
            }
        }
    }

    private func disconnect(result: @escaping FlutterResult) {
        if #available(iOS 11.0, *) {
            getSSID { (sSSID) in
                if let ssid = sSSID {
                    print("Trying to disconnect from '\(ssid)'")
                    NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
                    result(true)
                } else {
                    print("Not connected to a network")
                    result(FlutterError(code: "NOT_CONNECTED",
                                      message: "Not connected to any WiFi network",
                                      details: "Cannot disconnect - device is not connected to any WiFi network"))
                }
            }
        } else {
            print("disconnect not available on this iOS version")
            result(FlutterError(code: "CONFIGURATION_FAILED",
                              message: "iOS version not supported",
                              details: "NEHotspotConfiguration requires iOS 11.0 or later"))
        }
    }

    private func getSSID(result: @escaping (String?) -> ()) {
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent(completionHandler: { currentNetwork in
                result(currentNetwork?.ssid);
            })
        } else {
            if let interfaces = CNCopySupportedInterfaces() as NSArray? {
                for interface in interfaces {
                    if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                        result(interfaceInfo[kCNNetworkInfoKeySSID as String] as? String)
                        return
                    }
                }
            }
            result(nil)
        }
    }

    private func getBSSID(result: @escaping (String?) -> ()) {
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent(completionHandler: { currentNetwork in
                result(currentNetwork?.bssid);
            })
        } else {
            if let interfaces = CNCopySupportedInterfaces() as NSArray? {
                for interface in interfaces {
                    if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                        result(interfaceInfo[kCNNetworkInfoKeyBSSID as String] as? String)
                        return
                    }
                }
            }
            result(nil)
        }
    }
    
    private func getCurrentSignalStrength(result: FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    private func getFrequency(result: FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    private func getIP(result: FlutterResult) {
        guard let interface = getNetworkInterface(family: AF_INET) else {
            return result(nil)
        }
        
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                    &hostname, socklen_t(hostname.count),
                    nil, socklen_t(0), NI_NUMERICHOST)

        result(String(cString: hostname))
    }
    
    private func getNetworkInterface(family: Int32) -> ifaddrs? {
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            if ifptr.pointee.ifa_addr.pointee.sa_family == UInt8(family) {
                if String(cString: ifptr.pointee.ifa_name) == "en0" {
                    freeifaddrs(ifaddr)
                    return ifptr.pointee
                }
            }
        }
        freeifaddrs(ifaddr)
        return nil
    }

    private func removeWifiNetwork(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments
        let sPrefixSSID = (arguments as! [String : String])["prefix_ssid"] ?? ""
        if (sPrefixSSID == "") {
            print("No prefix SSID was given!")
            result(nil)
        }
        
        if #available(iOS 11.0, *) {
            NEHotspotConfigurationManager.shared.getConfiguredSSIDs { (htSSID) in
                for sIncSSID in htSSID {
                    if (sPrefixSSID != "" && sIncSSID.hasPrefix(sPrefixSSID)) {
                        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: sIncSSID)
                    }
                }
            }
            result(true)
        } else {
            print("Not removed")
            result(nil)
        }
    }

    private func isRegisteredWifiNetwork(call: FlutterMethodCall, result: FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    private func isWiFiAPEnabled(result: FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    private func setWiFiAPEnabled(call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments
        let state = (arguments as! [String : Bool])["state"]
        if (state != nil) {
            print("Setting AP WiFi Enable : \(state ?? false ? "enable" : "disable")")
            result(FlutterMethodNotImplemented)
        } else {
            result(nil)
        }
    }

    private func getWiFiAPState(result: FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    private func getClientList(result: FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    private func getWiFiAPSSID(result: FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    private func setWiFiAPSSID(call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments
        let ssid = (arguments as! [String : String])["ssid"]
        if (ssid != nil) {
            print("Setting AP WiFi SSID : '\(ssid ?? "")'")
            result(FlutterMethodNotImplemented)
        } else {
            result(nil)
        }
    }

    private func isSSIDHidden(result: FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    private func setSSIDHidden(call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments
        let hidden = (arguments as! [String : Bool])["hidden"]
        if (hidden != nil) {
            print("Setting AP WiFi Visibility : \(((hidden ?? false) ? "hidden" : "visible"))")
            result(FlutterMethodNotImplemented)
        } else {
            result(nil)
        }
    }

    private func getWiFiAPPreSharedKey(result: FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    private func setWiFiAPPreSharedKey(call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments
        let preSharedKey = (arguments as! [String : String])["preSharedKey"]
        if (preSharedKey != nil) {
            print("Setting AP WiFi PreSharedKey : '\(preSharedKey ?? "")'")
            result(FlutterMethodNotImplemented)
        } else {
            result(nil)
        }
    }
}

/// Used to enforce local network usage for iOSv14+
/// For more background on this, see [Triggering the Local Network Privacy Alert](https://developer.apple.com/forums/thread/663768).
func triggerLocalNetworkPrivacyAlert() {
    let sock4 = socket(AF_INET, SOCK_DGRAM, 0)
    guard sock4 >= 0 else { return }
    defer { close(sock4) }
    let sock6 = socket(AF_INET6, SOCK_DGRAM, 0)
    guard sock6 >= 0 else { return }
    defer { close(sock6) }
    
    let addresses = addressesOfDiscardServiceOnBroadcastCapableInterfaces()
    var message = [UInt8]("!".utf8)
    for address in addresses {
        address.withUnsafeBytes { buf in
            let sa = buf.baseAddress!.assumingMemoryBound(to: sockaddr.self)
            let saLen = socklen_t(buf.count)
            let sock = sa.pointee.sa_family == AF_INET ? sock4 : sock6
            _ = sendto(sock, &message, message.count, MSG_DONTWAIT, sa, saLen)
        }
    }
}
/// Returns the addresses of the discard service (port 9) on every
/// broadcast-capable interface.
///
/// Each array entry is contains either a `sockaddr_in` or `sockaddr_in6`.
private func addressesOfDiscardServiceOnBroadcastCapableInterfaces() -> [Data] {
    var addrList: UnsafeMutablePointer<ifaddrs>? = nil
    let err = getifaddrs(&addrList)
    guard err == 0, let start = addrList else { return [] }
    defer { freeifaddrs(start) }
    return sequence(first: start, next: { $0.pointee.ifa_next })
        .compactMap { i -> Data? in
            guard
                (i.pointee.ifa_flags & UInt32(bitPattern: IFF_BROADCAST)) != 0,
                let sa = i.pointee.ifa_addr
            else { return nil }
            var result = Data(UnsafeRawBufferPointer(start: sa, count: Int(sa.pointee.sa_len)))
            switch CInt(sa.pointee.sa_family) {
            case AF_INET:
                result.withUnsafeMutableBytes { buf in
                    let sin = buf.baseAddress!.assumingMemoryBound(to: sockaddr_in.self)
                    sin.pointee.sin_port = UInt16(9).bigEndian
                }
            case AF_INET6:
                result.withUnsafeMutableBytes { buf in
                    let sin6 = buf.baseAddress!.assumingMemoryBound(to: sockaddr_in6.self)
                    sin6.pointee.sin6_port = UInt16(9).bigEndian
                }
            default:
                return nil
            }
            return result
        }
}
