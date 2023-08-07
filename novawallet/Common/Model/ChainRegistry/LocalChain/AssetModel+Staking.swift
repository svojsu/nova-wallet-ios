import Foundation

extension AssetModel {
    var supportsNominationPoolsStaking: Bool {
        guard let stakings = stakings else {
            return false
        }

        return stakings.contains(.nominationPools)
    }
}
