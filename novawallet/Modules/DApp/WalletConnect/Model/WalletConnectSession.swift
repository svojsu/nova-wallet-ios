import Foundation

struct WalletConnectSession {
    let sessionId: String
    let pairingId: String
    let wallet: MetaAccountModel?
    let networks: WalletConnectChainsResolution
    let dAppName: String?
    let dAppHost: String?
    let dAppIcon: URL?
    let active: Bool
}
