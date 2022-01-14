import Foundation

struct DAppAuthRequest {
    let identifier: String
    let wallet: MetaAccountModel
    let dApp: String
    let dAppIcon: URL?
}

struct DAppAuthResponse {
    let approved: Bool
}