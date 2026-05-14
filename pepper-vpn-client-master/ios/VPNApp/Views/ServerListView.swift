import SwiftUI

struct ServerListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ServerListViewModel()
    @State private var showAddSubscription = false
    @State private var selectedConfig: VLESSConfig? = nil
    @StateObject private var vpnManager = VPNManager.shared

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.configs.isEmpty {
                    VStack(spacing: 16) {
                        Text("No servers\nTap + to add subscription")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.configs) { config in
                            ServerRowView(
                                config: config,
                                isSelected: selectedConfig?.id == config.id
                            )
                            .onTapGesture {
                                selectedConfig = config
                                Task {
                                    do {
                                        try await vpnManager.connect(config: config)
                                        dismiss()
                                    } catch {
                                        // Handle error if needed
                                    }
                                }
                            }
                        }
                        .onDelete(perform: viewModel.remove)
                    }
                }
            }
            .navigationTitle("Servers")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSubscription = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSubscription) {
                AddSubscriptionView(viewModel: viewModel)
            }
            .task {
                viewModel.loadSaved()
            }
        }
    }
}

struct ServerRowView: View {
    let config: VLESSConfig
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(config.name ?? config.host)
                    .font(.headline)
                
                Text("\(config.host):\(config.port)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
            
            Text(securityText)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(securityColor)
                .foregroundColor(.white)
                .cornerRadius(4)
        }
        .contentShape(Rectangle()) // Make the entire row tappable
    }
    
    private var securityText: String {
        switch config.security.lowercased() {
        case "reality":
            return "REALITY"
        case "tls":
            return "TLS"
        default:
            return "NONE"
        }
    }
    
    private var securityColor: Color {
        switch config.security.lowercased() {
        case "reality":
            return .purple
        case "tls":
            return .blue
        default:
            return .gray
        }
    }
}

class ServerListViewModel: ObservableObject {
    @Published var configs: [VLESSConfig] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let userDefaultsKey = "saved_configs"
    
    func addSubscription(urlString: String) async {
        // Validate URL
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Call VLESSParser.fetchSubscription(url:)
            let subscription = try await VLESSParser.fetchSubscription(url: url)
            
            // Append new configs (avoid duplicates by uuid)
            var existingUUIDs = Set(configs.map { $0.id })
            var newConfigs = configs
            
            for config in subscription.configs {
                if !existingUUIDs.contains(config.id) {
                    newConfigs.append(config)
                    existingUUIDs.insert(config.id)
                }
            }
            
            configs = newConfigs
            
            // Save to UserDefaults as JSON (key: "saved_configs")
            saveToUserDefaults()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadSaved() {
        // Load from UserDefaults key "saved_configs"
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            configs = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            configs = try decoder.decode([VLESSConfig].self, from: data)
        } catch {
            configs = []
        }
    }
    
    func remove(at offsets: IndexSet) {
        configs.remove(atOffsets: offsets)
        // Save to UserDefaults
        saveToUserDefaults()
    }
    
    private func saveToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(configs)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            // Handle error if needed
        }
    }
}

struct AddSubscriptionView: View {
    @ObservedObject var viewModel: ServerListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var urlString = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Subscription URL", text: $urlString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Import") {
                    Task {
                        await viewModel.addSubscription(urlString: urlString)
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(urlString.isEmpty || viewModel.isLoading)
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}