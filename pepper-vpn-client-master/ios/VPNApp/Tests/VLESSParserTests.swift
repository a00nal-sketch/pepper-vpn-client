import XCTest
@testable import VPNApp

final class VLESSParserTests: XCTestCase {
    
    func testParseValidVLESSURI() throws {
        // Test URI from requirements
        let uri = "vless://12345678-1234-1234-1234-123456789012@example.com:443?encryption=none&security=reality&pbk=abc123&sni=example.com&fp=chrome&flow=xtls-rprx-vision#MyServer"
        
        let config = try VLESSParser.parse(uri: uri)
        
        // Assert all fields are parsed correctly
        XCTAssertEqual(config.uuid, "12345678-1234-1234-1234-123456789012")
        XCTAssertEqual(config.host, "example.com")
        XCTAssertEqual(config.port, 443)
        XCTAssertEqual(config.encryption, "none")
        XCTAssertEqual(config.security, "reality")
        XCTAssertEqual(config.pbk, "abc123")
        XCTAssertEqual(config.sni, "example.com")
        XCTAssertEqual(config.fp, "chrome")
        XCTAssertEqual(config.flow, "xtls-rprx-vision")
        XCTAssertEqual(config.name, "MyServer")
        XCTAssertNil(config.sid)
    }
    
    func testParseVLESSURIWithTLS() throws {
        let uri = "vless://12345678-1234-1234-1234-123456789012@example.com:443?encryption=none&security=tls&sni=example.com&fp=chrome#MyServer"
        
        let config = try VLESSParser.parse(uri: uri)
        
        XCTAssertEqual(config.uuid, "12345678-1234-1234-1234-123456789012")
        XCTAssertEqual(config.host, "example.com")
        XCTAssertEqual(config.port, 443)
        XCTAssertEqual(config.encryption, "none")
        XCTAssertEqual(config.security, "tls")
        XCTAssertEqual(config.sni, "example.com")
        XCTAssertEqual(config.fp, "chrome")
        XCTAssertEqual(config.name, "MyServer")
        XCTAssertNil(config.pbk)
        XCTAssertNil(config.sid)
        XCTAssertNil(config.flow)
    }
    
    func testParseVLESSURIWithDefaultPort() throws {
        let uri = "vless://12345678-1234-1234-1234-123456789012@example.com?encryption=none&security=none"
        
        let config = try VLESSParser.parse(uri: uri)
        
        XCTAssertEqual(config.uuid, "12345678-1234-1234-1234-123456789012")
        XCTAssertEqual(config.host, "example.com")
        XCTAssertEqual(config.port, 443) // Default port
        XCTAssertEqual(config.encryption, "none")
        XCTAssertEqual(config.security, "none")
    }
    
    func testParseVLESSURIWithREALITYParams() throws {
        let uri = "vless://12345678-1234-1234-1234-123456789012@example.com:8443?encryption=none&security=reality&pbk=publickey123&sid=shortid456&sni=example.com&fp=chrome&flow=xtls-rprx-vision#REALITYServer"
        
        let config = try VLESSParser.parse(uri: uri)
        
        XCTAssertEqual(config.uuid, "12345678-1234-1234-1234-123456789012")
        XCTAssertEqual(config.host, "example.com")
        XCTAssertEqual(config.port, 8443)
        XCTAssertEqual(config.encryption, "none")
        XCTAssertEqual(config.security, "reality")
        XCTAssertEqual(config.pbk, "publickey123")
        XCTAssertEqual(config.sid, "shortid456")
        XCTAssertEqual(config.sni, "example.com")
        XCTAssertEqual(config.fp, "chrome")
        XCTAssertEqual(config.flow, "xtls-rprx-vision")
        XCTAssertEqual(config.name, "REALITYServer")
    }
    
    func testParseInvalidURIFormat() {
        let invalidURIs = [
            "invalid",
            "vless://",
            "http://example.com"
        ]
        
        for uri in invalidURIs {
            XCTAssertThrowsError(try VLESSParser.parse(uri: uri)) { error in
                XCTAssertEqual(error as? VLESSParserError, VLESSParserError.invalidURI)
            }
        }
    }
    
    func testParseInvalidUUID() {
        let uri = "vless://invalid-uuid@example.com:443?encryption=none&security=none"
        
        XCTAssertThrowsError(try VLESSParser.parse(uri: uri)) { error in
            XCTAssertEqual(error as? VLESSParserError, VLESSParserError.invalidUUID)
        }
    }
    
    func testParseInvalidPort() {
        let uri = "vless://12345678-1234-1234-1234-123456789012@example.com:invalid?encryption=none&security=none"
        
        XCTAssertThrowsError(try VLESSParser.parse(uri: uri)) { error in
            XCTAssertEqual(error as? VLESSParserError, VLESSParserError.invalidPort)
        }
    }
    
    func testParseSubscription() throws {
        // Create a subscription with multiple VLESS URIs
        let uris = [
            "vless://12345678-1234-1234-1234-123456789012@example.com:443?encryption=none&security=reality&pbk=abc123&sni=example.com&fp=chrome&flow=xtls-rprx-vision#MyServer",
            "vless://12345678-1234-1234-1234-123456789012@example2.com:8443?encryption=none&security=tls&sni=example2.com&fp=chrome#MyServer2"
        ]
        
        let subscriptionContent = uris.joined(separator: "\n")
        let base64Subscription = subscriptionContent.data(using: .utf8)?.base64EncodedString() ?? ""
        
        let subscription = try VLESSParser.parseSubscription(base64: base64Subscription)
        
        XCTAssertEqual(subscription.configs.count, 2)
        
        let firstConfig = subscription.configs[0]
        XCTAssertEqual(firstConfig.host, "example.com")
        XCTAssertEqual(firstConfig.security, "reality")
        
        let secondConfig = subscription.configs[1]
        XCTAssertEqual(secondConfig.host, "example2.com")
        XCTAssertEqual(secondConfig.security, "tls")
    }
    
    func testParseSubscriptionWithInvalidURIs() throws {
        // Subscription with one valid and one invalid URI
        let uris = [
            "vless://12345678-1234-1234-1234-123456789012@example.com:443?encryption=none&security=reality&pbk=abc123&sni=example.com&fp=chrome&flow=xtls-rprx-vision#MyServer",
            "invalid-uri",
            "vless://12345678-1234-1234-1234-123456789012@example2.com:8443?encryption=none&security=tls&sni=example2.com&fp=chrome#MyServer2"
        ]
        
        let subscriptionContent = uris.joined(separator: "\n")
        let base64Subscription = subscriptionContent.data(using: .utf8)?.base64EncodedString() ?? ""
        
        let subscription = try VLESSParser.parseSubscription(base64: base64Subscription)
        
        // Should only contain the two valid URIs
        XCTAssertEqual(subscription.configs.count, 2)
    }
    
    func testParseSubscriptionInvalidBase64() {
        // Use valid base64 that decodes to non-UTF8 bytes
        let invalidBase64 = Data([0xFF, 0xFE, 0xFD]).base64EncodedString()
        
        XCTAssertThrowsError(try VLESSParser.parseSubscription(base64: invalidBase64)) { error in
            XCTAssertEqual(error as? VLESSParserError, VLESSParserError.decodingFailed)
        }
    }
    
    func testParseIPv6Host() throws {
        let uri = "vless://12345678-1234-1234-1234-123456789012@[::1]:443?encryption=none&security=none"
        let config = try VLESSParser.parse(uri: uri)
        XCTAssertEqual(config.host, "::1")  // brackets should be stripped
        XCTAssertEqual(config.port, 443)
    }
    
    func testParseEmptySubscription() throws {
        // Create base64 of a string with no vless:// URIs
        let content = "hello\nworld"
        let base64Subscription = content.data(using: .utf8)?.base64EncodedString() ?? ""
        
        let subscription = try VLESSParser.parseSubscription(base64: base64Subscription)
        XCTAssertEqual(subscription.configs.count, 0)  // Should be empty, not throw an error
    }
    
    func testToXrayJSONWithREALITY() throws {
        let uri = "vless://12345678-1234-1234-1234-123456789012@example.com:443?encryption=none&security=reality&pbk=abc123&sni=example.com&fp=chrome&flow=xtls-rprx-vision#MyServer"
        
        let config = try VLESSParser.parse(uri: uri)
        let json = config.toXrayJSON()
        
        // Check that the JSON contains expected elements
        XCTAssertTrue(json.contains("\"protocol\": \"vless\""))
        XCTAssertTrue(json.contains("\"address\": \"example.com\""))
        XCTAssertTrue(json.contains("\"port\": 443"))
        XCTAssertTrue(json.contains("\"id\": \"12345678-1234-1234-1234-123456789012\""))
        XCTAssertTrue(json.contains("\"security\": \"reality\""))
        XCTAssertTrue(json.contains("\"publicKey\": \"abc123\""))
        XCTAssertTrue(json.contains("\"serverName\": \"example.com\""))
        XCTAssertTrue(json.contains("\"fingerprint\": \"chrome\""))
        XCTAssertTrue(json.contains("\"flow\": \"xtls-rprx-vision\""))
        XCTAssertTrue(json.contains("\"port\": 10808"))
        XCTAssertTrue(json.contains("\"listen\": \"127.0.0.1\""))
        XCTAssertTrue(json.contains("\"protocol\": \"socks\""))
    }
    
    func testToXrayJSONWithTLS() throws {
        let uri = "vless://12345678-1234-1234-1234-123456789012@example.com:443?encryption=none&security=tls&sni=example.com&fp=chrome#MyServer"
        
        let config = try VLESSParser.parse(uri: uri)
        let json = config.toXrayJSON()
        
        // Check that the JSON contains expected elements
        XCTAssertTrue(json.contains("\"protocol\": \"vless\""))
        XCTAssertTrue(json.contains("\"address\": \"example.com\""))
        XCTAssertTrue(json.contains("\"port\": 443"))
        XCTAssertTrue(json.contains("\"id\": \"12345678-1234-1234-1234-123456789012\""))
        XCTAssertTrue(json.contains("\"security\": \"tls\""))
        XCTAssertTrue(json.contains("\"serverName\": \"example.com\""))
        XCTAssertTrue(json.contains("\"fingerprint\": \"chrome\""))
        XCTAssertTrue(json.contains("\"port\": 10808"))
        XCTAssertTrue(json.contains("\"listen\": \"127.0.0.1\""))
        XCTAssertTrue(json.contains("\"protocol\": \"socks\""))
    }
    
    func testPercentEncodedParameters() throws {
        // URI with percent-encoded parameters
        let uri = "vless://12345678-1234-1234-1234-123456789012@example.com:443?encryption=none&security=tls&sni=example%2Ecom&fp=chrome#My%20Server"
        
        let config = try VLESSParser.parse(uri: uri)
        
        XCTAssertEqual(config.sni, "example.com")
        XCTAssertEqual(config.name, "My Server")
    }
}