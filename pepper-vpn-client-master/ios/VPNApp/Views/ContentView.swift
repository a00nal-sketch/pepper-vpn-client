import SwiftUI
import NetworkExtension

struct ContentView: View {
    @StateObject private var vpnManager = VPNManager.shared
    @State private var showServerList = false
    @State private var errorMessage: String? = nil
    @State private var showError = false

    var body: some View {
        VStack(spacing: 16) {
            
            // Title
            Text("VPN")
                .font(.largeTitle).bold()
                .padding(.top, 40)
            
            Spacer()
            
            // Connect button
            VStack(spacing: 12) {
                Button(action: connectOrDisconnect) {
                    ZStack {
                        Circle()
                            .fill(buttonColor)
                            .frame(width: 140, height: 140)
                        if vpnManager.status == .connecting || vpnManager.status == .disconnecting {
                            ProgressView().tint(.white).scaleEffect(1.5)
                        } else {
                            Image(systemName: vpnManager.status == .connected ? "stop.fill" : "play.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Text(vpnManager.status == .connected ? "DISCONNECT" : "CONNECT")
                    .font(.caption).bold()
                    .foregroundColor(.secondary)
                
                Text(vpnManager.statusDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let server = vpnManager.connectedServer {
                    Text(server.name ?? server.host)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Bottom bar
            HStack {
                Spacer()
                Button {
                    showServerList = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "server.rack")
                        Text("Servers").font(.caption)
                    }
                }
                Spacer()
                Button {
                    // Settings placeholder
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "gear")
                        Text("Settings").font(.caption)
                    }
                }
                Spacer()
            }
            .padding(.bottom, 24)
        }
        .task {
            try? await vpnManager.loadOrCreate()
        }
        .sheet(isPresented: $showServerList) {
            ServerListView()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
    
    private var buttonColor: Color {
        switch vpnManager.status {
        case .connected: return .green
        case .connecting, .disconnecting: return .gray
        default: return .blue
        }
    }
    
    private func connectOrDisconnect() {
        switch vpnManager.status {
        case .connected:
            vpnManager.disconnect()
        case .disconnected, .invalid:
            Task {
                do {
                    if let server = vpnManager.connectedServer {
                        try await vpnManager.connect(config: server)
                    } else {
                        showServerList = true
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        default:
            break
        }
    }
}

