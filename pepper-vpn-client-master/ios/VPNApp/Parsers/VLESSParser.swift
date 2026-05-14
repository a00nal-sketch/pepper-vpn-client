import Foundation

// MARK: - VLESS Configuration Models

/// Represents a single VLESS server configuration
struct VLESSConfig: Codable, Identifiable {
    let uuid: String
    let host: String
    let port: Int
    let encryption: String
    let security: String
    let sni: String?
    let pbk: String?  // Public key for REALITY
    let sid: String?  // Short ID for REALITY
    let fp: String?   // Fingerprint for uTLS
    let flow: String? // Flow control (xtls-rprx-vision)
    let name: String? // From fragment after #
    
    // MARK: - Identifiable
    var id: String { uuid }
    
    /// Converts the VLESS configuration to a valid Xray-core JSON configuration string
    /// - Returns: JSON string for Xray-core
    func toXrayJSON() -> String {
        var outboundSettings: [String: Any] = [
            "vnext": [
                [
                    "address": host,
                    "port": port,
                    "users": [
                        [
                            "id": uuid,
                            "encryption": encryption,
                            "flow": flow ?? ""
                        ]
                    ]
                ]
            ]
        ]
        
        var streamSettings: [String: Any] = [
            "network": "tcp",
            "security": security
        ]
        
        // Add TLS settings if security is tls
        if security == "tls" {
            var tlsSettings: [String: Any] = [
                "serverName": sni ?? host
            ]
            
            if let fingerprint = fp {
                tlsSettings["fingerprint"] = fingerprint
            }
            
            streamSettings["tlsSettings"] = tlsSettings
        }
        // Add REALITY settings if security is reality
        else if security == "reality" {
            var realitySettings: [String: Any] = [
                "serverName": sni ?? host,
                "show": false
            ]
            
            if let publicKey = pbk {
                realitySettings["publicKey"] = publicKey
            }
            
            if let shortId = sid {
                realitySettings["shortId"] = shortId
            }
            
            if let fingerprint = fp {
                realitySettings["fingerprint"] = fingerprint
            }
            
            streamSettings["realitySettings"] = realitySettings
            streamSettings["network"] = "tcp"
        }
        
        let config: [String: Any] = [
            "log": [
                "loglevel": "warning"
            ],
            "inbounds": [
                [
                    "port": 10808,
                    "listen": "127.0.0.1",
                    "protocol": "socks",
                    "settings": [
                        "udp": true,
                        "auth": "noauth"
                    ]
                ]
            ],
            "outbounds": [
                [
                    "protocol": "vless",
                    "settings": outboundSettings,
                    "streamSettings": streamSettings
                ]
            ]
        ]
        
        return toJSONString(config)
    }
    
    /// Converts a dictionary to a JSON string
    /// - Parameter dict: Dictionary to convert
    /// - Returns: JSON string representation
    private func toJSONString(_ dict: [String: Any]) -> String {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        return jsonString
    }
}

/// Represents a subscription containing multiple VLESS configurations
struct VLESSSubscription {
    let configs: [VLESSConfig]
}

// MARK: - VLESS Parser Error

/// Errors that can occur during VLESS parsing
enum VLESSParserError: Error, LocalizedError {
    case invalidURI
    case invalidUUID
    case invalidHost
    case invalidPort
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURI:
            return "Invalid VLESS URI format"
        case .invalidUUID:
            return "Invalid UUID format"
        case .invalidHost:
            return "Invalid host format"
        case .invalidPort:
            return "Invalid port format"
        case .decodingFailed:
            return "Failed to decode subscription data"
        }
    }
}

// MARK: - VLESS Parser

/// Parser for VLESS URIs and subscriptions
struct VLESSParser {
    
    /// Parses a single VLESS URI into a VLESSConfig
    /// - Parameter uri: VLESS URI string
    /// - Returns: Parsed VLESSConfig
    /// - Throws: VLESSParserError if parsing fails
    static func parse(uri: String) throws -> VLESSConfig {
        // Check if URI starts with vless://
        guard uri.hasPrefix("vless://") else {
            throw VLESSParserError.invalidURI
        }
        
        // Remove the scheme
        let uriWithoutScheme = String(uri.dropFirst("vless://".count))
        
        // Split into user info and host info
        let components = uriWithoutScheme.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
        guard components.count == 2 else {
            throw VLESSParserError.invalidURI
        }
        
        let userInfo = String(components[0])
        let hostInfoAndParams = String(components[1])
        
        // Parse UUID
        let uuid = userInfo
        
        // Validate UUID format (basic validation)
        guard isValidUUID(uuid) else {
            throw VLESSParserError.invalidUUID
        }
        
        // Split host info and parameters
        let hostInfoComponents = hostInfoAndParams.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        guard !hostInfoComponents.isEmpty else {
            throw VLESSParserError.invalidURI
        }
        
        let hostAndPortString = String(hostInfoComponents[0])
        let paramsString = hostInfoComponents.count > 1 ? String(hostInfoComponents[1]) : ""
        
        // Parse host and port - handle IPv6 addresses like [::1]:443
        var host: String
        var port = 443 // Default port

        if hostAndPortString.hasPrefix("[") {
            // IPv6 address
            guard let closingBracket = hostAndPortString.firstIndex(of: "]") else {
                throw VLESSParserError.invalidHost
            }
            let afterBracket = hostAndPortString.index(after: closingBracket)
            host = String(hostAndPortString[hostAndPortString.index(after: hostAndPortString.startIndex)..<closingBracket])
            
            if afterBracket < hostAndPortString.endIndex && hostAndPortString[afterBracket] == ":" {
                let portString = String(hostAndPortString[hostAndPortString.index(after: afterBracket)...])
                guard let parsedPort = Int(portString) else {
                    throw VLESSParserError.invalidPort
                }
                port = parsedPort
            }
        } else {
            // Regular hostname or IPv4
            let hostPortComponents = hostAndPortString.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            host = String(hostPortComponents[0])
            
            if hostPortComponents.count > 1 {
                guard let parsedPort = Int(String(hostPortComponents[1])) else {
                    throw VLESSParserError.invalidPort
                }
                port = parsedPort
            }
        }

        guard !host.isEmpty else {
            throw VLESSParserError.invalidHost
        }
        
        // Parse parameters
        var params: [String: String] = [:]
        let paramPairs = paramsString.split(separator: "&")
        for pair in paramPairs {
            let keyValue = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            if !keyValue.isEmpty {
                let key = String(keyValue[0])
                let value = keyValue.count > 1 ? String(keyValue[1]) : ""
                params[key] = value.isEmpty ? nil : value
            }
        }
        
        // Extract fragment (name)
        var name: String?
        if let fragmentRange = uri.range(of: "#") {
            name = String(uri[fragmentRange.upperBound...])
        }
        
        // Decode percent-encoded values
        let encryption = decodePercentEncodedString(params["encryption"] ?? "none")
        let security = decodePercentEncodedString(params["security"] ?? "none")
        let sni = params["sni"].map { decodePercentEncodedString($0) }
        let pbk = params["pbk"].map { decodePercentEncodedString($0) }
        let sid = params["sid"].map { decodePercentEncodedString($0) }
        let fp = params["fp"].map { decodePercentEncodedString($0) }
        let flow = params["flow"].map { decodePercentEncodedString($0) }
        
        return VLESSConfig(
            uuid: uuid,
            host: host,
            port: port,
            encryption: encryption,
            security: security,
            sni: sni,
            pbk: pbk,
            sid: sid,
            fp: fp,
            flow: flow,
            name: name
        )
    }
    
    /// Parses a base64-encoded subscription into a VLESSSubscription
    /// - Parameter base64: Base64-encoded subscription string
    /// - Returns: Parsed VLESSSubscription
    /// - Throws: VLESSParserError if parsing fails
    static func parseSubscription(base64: String) throws -> VLESSSubscription {
        // Remove any whitespace
        let cleanBase64 = base64.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add padding if needed
        var paddedBase64 = cleanBase64
        while paddedBase64.count % 4 != 0 {
            paddedBase64 += "="
        }
        
        // Decode base64
        guard let data = Data(base64Encoded: paddedBase64) else {
            throw VLESSParserError.decodingFailed
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw VLESSParserError.decodingFailed
        }
        
        // Split by newlines to get individual URIs
        let uris = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.hasPrefix("vless://") }
        
        var configs: [VLESSConfig] = []
        for uri in uris {
            do {
                let config = try parse(uri: uri)
                configs.append(config)
            } catch {
                // Skip invalid URIs but continue processing others
                continue
            }
        }
        
        return VLESSSubscription(configs: configs)
    }
    
    /// Fetches and parses a subscription from a URL
    /// - Parameter url: URL to fetch subscription from
    /// - Returns: Parsed VLESSSubscription
    /// - Throws: VLESSParserError if fetching or parsing fails
    @available(iOS 13.0, *)
    static func fetchSubscription(url: URL) async throws -> VLESSSubscription {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw VLESSParserError.decodingFailed
            }
            
            guard let base64String = String(data: data, encoding: .utf8) else {
                throw VLESSParserError.decodingFailed
            }
            
            // Let parseSubscription errors propagate as-is
            return try parseSubscription(base64: base64String)
        } catch let error as VLESSParserError {
            throw error  // re-throw our own errors unchanged
        } catch {
            throw VLESSParserError.decodingFailed  // only wrap URLSession errors
        }
    }
    
    /// Validates UUID format (basic validation)
    /// - Parameter uuid: UUID string to validate
    /// - Returns: True if valid, false otherwise
    private static func isValidUUID(_ uuid: String) -> Bool {
        // Basic UUID validation (8-4-4-4-12 format)
        let uuidRegex = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
        let regex = try? NSRegularExpression(pattern: uuidRegex)
        let range = NSRange(location: 0, length: uuid.utf16.count)
        return regex?.firstMatch(in: uuid, options: [], range: range) != nil
    }
    
    /// Decodes percent-encoded strings
    /// - Parameter string: Percent-encoded string
    /// - Returns: Decoded string
    private static func decodePercentEncodedString(_ string: String) -> String {
        return string.removingPercentEncoding ?? string
    }
}