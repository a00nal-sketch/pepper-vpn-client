# TUNNEL ANALYSIS

## File Analysis

### 1. src/tun2socks/outline/xray_mobile/xray.go

#### Functions:
1. `func writeConfig(configFile string, host string, port int, uuid string) error`
2. `func StartXrayServer(configDir string, config string) string`
3. `func StopXrayServer() string`

#### Function Details:

**writeConfig**
- **Description**: Creates a JSON configuration file for Xray-core with VLESS protocol settings
- **Inputs**: 
  - configFile: path to the configuration file to create
  - host: server address
  - port: server port
  - uuid: user ID for authentication
- **Returns**: error if file writing fails
- **Dependencies**: fmt, os packages

**StartXrayServer**
- **Description**: Initializes and starts the Xray-core server with the provided configuration
- **Inputs**: 
  - configDir: directory containing configuration files
  - config: JSON configuration string
- **Returns**: status string with geo data information
- **Dependencies**: libxray package, os package, fmt package, log package

**StopXrayServer**
- **Description**: Stops the running Xray-core server
- **Inputs**: None
- **Returns**: status string from libxray
- **Dependencies**: libxray package

### 2. src/tun2socks/outline/xray_mobile/tunnel.go

#### Functions:
1. `func newTunnel(tunWriter io.WriteCloser) (tunnel.Tunnel, error)`

#### Types:
1. `type Tunnel interface`
2. `type localSocksTunnel struct`

#### Function Details:

**newTunnel**
- **Description**: Creates a new tunnel that routes packets from TUN device to a local SOCKS proxy
- **Inputs**: tunWriter - writer for the TUN device
- **Returns**: tunnel.Tunnel interface and error if creation fails
- **Dependencies**: errors package, go-tun2socks/core, go-tun2socks/proxy/socks, tun2socks/tunnel

**localSocksTunnel.UpdateUDPSupport**
- **Description**: Method that indicates UDP support is enabled
- **Inputs**: None
- **Returns**: true (boolean)
- **Dependencies**: None

### 3. src/tun2socks/outline/xray_mobile/tunnel_darwin.go

#### Functions:
1. `func init()`
2. `func ConnectLocalSocksTunnel(tunWriter tunnelDarwin.TunWriter) (tunnel.UpdatableUDPSupportTunnel, error)`

#### Function Details:

**init**
- **Description**: Initializes memory management settings for Apple VPN extensions
- **Inputs**: None
- **Returns**: None
- **Dependencies**: debug package, time package

**ConnectLocalSocksTunnel**
- **Description**: Entry point for creating a tunnel on Darwin (iOS/macOS) platforms that connects to a local SOCKS proxy
- **Inputs**: tunWriter - writer for the TUN device
- **Returns**: UpdatableUDPSupportTunnel interface and error if creation fails
- **Dependencies**: errors package, tun2socks/tunnel, tun2socks/tunnel_darwin

### 4. src/cordova/plugin/apple/src/OutlinePlugin.swift

#### Functions:
1. `func pluginInitialize()`
2. `func start(_ command: CDVInvokedUrlCommand)`
3. `func stop(_ command: CDVInvokedUrlCommand)`
4. `func isRunning(_ command: CDVInvokedUrlCommand)`
5. `func onStatusChange(_ command: CDVInvokedUrlCommand)`
6. `func onVpnStatusChange(vpnStatus: NEVPNStatus, tunnelId: String)`

#### Function Details:

**pluginInitialize**
- **Description**: Initializes the plugin with Sentry logger and sets up VPN status change handler
- **Inputs**: None
- **Returns**: None
- **Dependencies**: OutlineSentryLogger, OutlineNotification, OutlineTunnel

**start**
- **Description**: Starts the VPN tunnel with the provided configuration
- **Inputs**: command - CDVInvokedUrlCommand containing tunnel ID, tunnel type, and config JSON
- **Returns**: None (sends success/error via callback)
- **Dependencies**: OutlineVpn, CDVPluginResult

**stop**
- **Description**: Stops the VPN tunnel
- **Inputs**: command - CDVInvokedUrlCommand containing tunnel ID
- **Returns**: None (sends success via callback)
- **Dependencies**: OutlineVpn, CDVPluginResult

**isRunning**
- **Description**: Checks if a VPN tunnel is currently active
- **Inputs**: command - CDVInvokedUrlCommand containing tunnel ID
- **Returns**: None (sends boolean result via callback)
- **Dependencies**: OutlineVpn, CDVPluginResult

**onStatusChange**
- **Description**: Registers a callback for VPN status change notifications
- **Inputs**: command - CDVInvokedUrlCommand containing tunnel ID
- **Returns**: None (stores callback ID)
- **Dependencies**: CDVPluginResult

**onVpnStatusChange**
- **Description**: Handles VPN status change notifications from NetworkExtension
- **Inputs**: vpnStatus - NEVPNStatus enum, tunnelId - string identifier
- **Returns**: None (sends status update via callback)
- **Dependencies**: NEVPNStatus, CDVPluginResult

### 5. src/www/app/outline_server_repository/access_key_serialization.ts

#### Functions:
1. `staticKeyToShadowsocksSessionConfig(staticKey: string): ShadowsocksSessionConfig`
2. `parseShadowsocksSessionConfigJson(responseJson: ShadowsocksServerConfig): ShadowsocksSessionConfig | null`
3. `parseXraySessionConfigJson(responseJson: XrayServerConfig): XraySessionConfig | null`
4. `fetchSessionConfig(configLocation: URL): Promise<ShadowsocksSessionConfig|XraySessionConfig>`

#### Function Details:

**staticKeyToShadowsocksSessionConfig**
- **Description**: Parses a Shadowsocks URI (ss://) into a session configuration object
- **Inputs**: staticKey - Shadowsocks URI string
- **Returns**: ShadowsocksSessionConfig object
- **Dependencies**: SHADOWSOCKS_URI parser, errors module

**parseShadowsocksSessionConfigJson**
- **Description**: Parses a JSON object containing Shadowsocks configuration into a session config
- **Inputs**: responseJson - ShadowsocksServerConfig object
- **Returns**: ShadowsocksSessionConfig object or null
- **Dependencies**: None

**parseXraySessionConfigJson**
- **Description**: Parses a JSON object containing Xray configuration into a session config
- **Inputs**: responseJson - XrayServerConfig object
- **Returns**: XraySessionConfig object or null
- **Dependencies**: None

**fetchSessionConfig**
- **Description**: Fetches and parses session configuration from a URL, handling both Shadowsocks and Xray configs
- **Inputs**: configLocation - URL to fetch configuration from
- **Returns**: Promise resolving to either ShadowsocksSessionConfig or XraySessionConfig
- **Dependencies**: fetch API, errors module, environment module

## Answers to Questions

### How does VLESS config get passed to Xray-core?

The VLESS configuration is passed to Xray-core through the `StartXrayServer` function in `xray.go`. The process works as follows:

1. In `access_key_serialization.ts`, the `fetchSessionConfig` function retrieves and parses the configuration, which can be either a Shadowsocks URI or a JSON configuration.
2. For Xray configurations, `parseXraySessionConfigJson` processes the JSON and returns an `XraySessionConfig` object containing the Xray configuration as a JSON string.
3. This configuration is eventually passed to the Go layer through the Cordova bridge.
4. In `xray.go`, the `StartXrayServer` function receives the configuration string and writes it to a file using `os.WriteFile`.
5. The Xray-core is then started with `libXray.RunXray`, which reads the configuration file to initialize the VLESS protocol settings.

The configuration includes VLESS-specific settings like:
- Protocol set to "vless"
- Server address and port
- User ID for authentication
- Stream settings including network type (quic), security (tls), and TLS settings

### What is the entry point for iOS tunnel start/stop?

The entry point for iOS tunnel start/stop is in `OutlinePlugin.swift`:

**Start Entry Point:**
1. `start` function in `OutlinePlugin.swift` - This is called from the JavaScript layer through Cordova
2. It calls `OutlineVpn.shared.start()` with the tunnel ID, type, and configuration
3. This eventually leads to `ConnectLocalSocksTunnel` in `tunnel_darwin.go` which creates the tunnel

**Stop Entry Point:**
1. `stop` function in `OutlinePlugin.swift` - This is called from the JavaScript layer through Cordova
2. It calls `OutlineVpn.shared.stop()` with the tunnel ID

The actual tunnel implementation uses NetworkExtension framework on iOS, with the Swift plugin serving as the bridge between the JavaScript UI and the native VPN implementation.

### Is there any VLESS URI parsing (vless://) or only JSON config?

Based on the analysis, there is **no direct vless:// URI parsing** implemented in these files. The implementation only handles:

1. **Shadowsocks URI parsing** - The `staticKeyToShadowsocksSessionConfig` function in `access_key_serialization.ts` parses `ss://` URIs using the `SHADOWSOCKS_URI` parser.

2. **JSON configuration parsing** - The code extensively handles JSON configurations:
   - `parseShadowsocksSessionConfigJson` for Shadowsocks JSON configs
   - `parseXraySessionConfigJson` for Xray/VLESS JSON configs
   - `fetchSessionConfig` can handle both URI and JSON responses

The `fetchSessionConfig` function does check if the response body starts with "ss://" to determine if it should parse it as a Shadowsocks URI, but there's no equivalent check for "vless://". Instead, VLESS configurations are expected to be provided as JSON objects that are parsed by `parseXraySessionConfigJson`.

The actual VLESS configuration is embedded within the JSON structure that gets passed to Xray-core, as seen in the `writeConfig` function in `xray.go` which creates a JSON configuration with "protocol": "vless".