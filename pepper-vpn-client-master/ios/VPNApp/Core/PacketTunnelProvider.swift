import NetworkExtension
import Foundation

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var tunnel: TunnelInterface?
    private var startCompletion: ((Error?) -> Void)?
    private var stopCompletion: (() -> Void)?
    
    // MARK: - Tunnel Lifecycle
    
    override func startTunnel(options: [String : NSObject]? = nil) async throws {
        NSLog("[PacketTunnelProvider] Starting tunnel")
        
        guard let options = options else {
            NSLog("[PacketTunnelProvider] Received connect request from system settings")
            let error = NSError(
                domain: NEVPNErrorDomain,
                code: NEVPNError.configurationDisabled.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Please use the PepperVPN app to connect."]
            )
            throw error
        }
        
        guard let configData = options["config"] as? Data,
              let config = try? JSONDecoder().decode(VLESSConfig.self, from: configData) else {
            NSLog("[PacketTunnelProvider] Failed to decode tunnel config")
            throw NSError(
                domain: NEVPNErrorDomain,
                code: NEVPNError.configurationInvalid.rawValue,
                userInfo: nil
            )
        }
        
        // Set tunnel network settings
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: config.host)
        settings.mtu = 1500
        
        // Configure DNS
        let dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        dnsSettings.matchDomains = [""] // Route all DNS through tunnel
        settings.dnsSettings = dnsSettings
        
        // Configure IP settings
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        let ipv6Settings = NEIPv6Settings(addresses: ["fd00::2"], networkPrefixLengths: [64])
        ipv6Settings.includedRoutes = [NEIPv6Route.default()]
        settings.ipv6Settings = ipv6Settings
        
        // Apply network settings
        try await setTunnelNetworkSettings(settings)
        NSLog("[PacketTunnelProvider] Tunnel network settings applied")
        
        // Start the tunnel interface
        tunnel = TunnelInterface()
        tunnel?.start()
        
        // Start reading packets
        readPackets()
        
        NSLog("[PacketTunnelProvider] Tunnel started successfully")
    }
    
    override func stopTunnel(with reason: NEProviderStopReason) async {
        NSLog("[PacketTunnelProvider] Stopping tunnel, reason: \(reason.rawValue)")
        tunnel?.stop()
        tunnel = nil
        cancelTunnelWithError(nil)
        NSLog("[PacketTunnelProvider] Tunnel stopped")
    }
    
    override func handleAppMessage(_ messageData: Data) async -> Data? {
        guard let message = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
              let action = message["action"] as? String else {
            return nil
        }
        
        NSLog("[PacketTunnelProvider] Received app message: \(action)")
        
        switch action {
        case "getTunnelId":
            let response: [String: Any] = ["tunnelId": ""]
            return try? JSONSerialization.data(withJSONObject: response)
        default:
            return nil
        }
    }
    
    // MARK: - Packet Processing
    
    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            
            for (index, packet) in packets.enumerated() {
                let protocolFamily = protocols[index].intValue
                self.tunnel?.write(packet, protocolFamily: protocolFamily)
            }
            
            // Continue reading packets
            self.readPackets()
        }
    }
    
    private func writePacket(_ packet: Data, protocolFamily: Int32) {
        packetFlow.writePackets([packet], withProtocols: [NSNumber(value: protocolFamily)])
    }
}

// MARK: - Tunnel Interface

private class TunnelInterface {
    private var isRunning = false
    private var queue = DispatchQueue(label: "com.peppervpn.tunnel")
    
    func start() {
        isRunning = true
        NSLog("[TunnelInterface] Started")
    }
    
    func stop() {
        isRunning = false
        NSLog("[TunnelInterface] Stopped")
    }
    
    func write(_ packet: Data, protocolFamily: Int32) {
        // Process packet through the tunnel
        // In a real implementation, this would route packets through Xray/VLESS
        queue.async { [weak self] in
            guard self?.isRunning == true else { return }
            // Packet processing logic here
        }
    }
}
