import NetworkExtension
import Foundation

@MainActor
class VPNManager: ObservableObject {
    static let shared = VPNManager()
    
    @Published var status: NEVPNStatus = .disconnected
    @Published var connectedServer: VLESSConfig? = nil
    
    private var vpnManager: NETunnelProviderManager?
    private var statusObserver: Any?
    
    enum VPNManagerError: Error, LocalizedError {
        case notConfigured
        case connectionFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "VPN not configured"
            case .connectionFailed(let reason):
                return "Connection failed: \(reason)"
            }
        }
    }
    
    private init() {}
    
    func loadOrCreate() async throws {
        // Load existing managers or create a new one
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        self.vpnManager = managers.first ?? NETunnelProviderManager()
        
        // Set localized description
        self.vpnManager?.localizedDescription = "VPN"
        
        // Save to preferences
        try await self.vpnManager?.saveToPreferences()
        
        // Observe status changes
        observeStatus()
    }
    
    func connect(config: VLESSConfig) async throws {
        guard let vpnManager = self.vpnManager else {
            throw VPNManagerError.notConfigured
        }
        
        // Create protocol configuration
        let protocolConfig = NETunnelProviderProtocol()
        protocolConfig.providerBundleIdentifier = "com.vpn.tunnel"
        protocolConfig.serverAddress = config.host
        protocolConfig.providerConfiguration = ["xrayConfig": config.toXrayJSON()]
        
        // Assign protocol to manager
        vpnManager.protocolConfiguration = protocolConfig
        
        // Save to preferences
        try await vpnManager.saveToPreferences()
        
        // Load from preferences
        try await vpnManager.loadFromPreferences()
        
        // Start VPN tunnel
        do {
            try vpnManager.connection.startVPNTunnel()
        } catch {
            throw VPNManagerError.connectionFailed(error.localizedDescription)
        }
        
        // Update connected server on main thread
        self.connectedServer = config
    }
    
    func disconnect() {
        // Stop VPN tunnel
        vpnManager?.connection.stopVPNTunnel()
        
        // Update connected server on main thread
        self.connectedServer = nil
    }
    
    private func observeStatus() {
        // Remove previous observer if exists
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Add observer for NEVPNStatusDidChange notification
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Get status from notification
            let status = (notification.object as? NEVPNConnection)?.status ?? .invalid
            
            // Update status on main thread
            self?.status = status
        }
    }
    
    var statusDescription: String {
        switch status {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnecting:
            return "Disconnecting..."
        case .disconnected:
            return "Disconnected"
        case .invalid:
            return "Invalid"
        case .reasserting:
            return "Reconnecting..."
        @unknown default:
            return "Unknown"
        }
    }
    
    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}