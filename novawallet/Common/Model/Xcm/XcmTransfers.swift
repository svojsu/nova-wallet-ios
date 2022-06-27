import Foundation
import SubstrateSdk
import BigInt

struct XcmTransfers: Decodable {
    let assetsLocation: [String: JSON]
    let instructions: [String: [String]]
    let networkBaseWeight: [String: String]
    let chains: [XcmChain]

    func assetLocation(for key: String) -> JSON? {
        assetsLocation[key]
    }

    func instructions(for key: String) -> [String]? {
        instructions[key]
    }

    func baseWeight(for chainId: String) -> BigUInt? {
        guard let baseWeight = networkBaseWeight[chainId] else {
            return nil
        }

        return BigUInt(baseWeight)
    }

    func getReservePath(for chainAssetId: ChainAssetId) -> XcmAsset.ReservePath? {
        guard let asset = asset(from: chainAssetId) else {
            return nil
        }

        guard let assetLocation = assetLocation(for: asset.assetLocation)?.multiLocation else {
            return nil
        }

        switch asset.assetLocationPath.type {
        case .absolute, .relative:
            return XcmAsset.ReservePath(type: asset.assetLocationPath.type, path: assetLocation)
        case .concrete:
            if let concretePath = asset.assetLocationPath.path {
                return XcmAsset.ReservePath(type: .concrete, path: concretePath)
            } else {
                return nil
            }
        }
    }

    func transferableAssetIds(from chainId: ChainModel.Id) -> Set<AssetModel.Id> {
        guard let chain = chains.first(where: { $0.chainId == chainId }) else {
            return Set()
        }

        let assetIds = chain.assets.map(\.assetId)
        return Set(assetIds)
    }

    func getReserveTransfering(from chainId: ChainModel.Id, assetId: AssetModel.Id) -> ChainModel.Id? {
        guard
            let chain = chains.first(where: { $0.chainId == chainId }),
            let asset = chain.assets.first(where: { $0.assetId == assetId }),
            let assetLocation = assetsLocation[asset.assetLocation] else {
            return nil
        }

        return assetLocation.chainId?.stringValue
    }

    func asset(from chainAssetId: ChainAssetId) -> XcmAsset? {
        guard let chain = chains.first(where: { $0.chainId == chainAssetId.chainId }) else {
            return nil
        }

        return chain.assets.first(where: { $0.assetId == chainAssetId.assetId })
    }

    func transfers(from chainAssetId: ChainAssetId) -> [XcmAssetTransfer] {
        guard
            let chain = chains.first(where: { $0.chainId == chainAssetId.chainId }),
            let xcmTransfers = chain.assets.first(where: { $0.assetId == chainAssetId.assetId })?.xcmTransfers else {
            return []
        }

        return xcmTransfers
    }

    func transfer(
        from chainAssetId: ChainAssetId,
        destinationChainId: ChainModel.Id
    ) -> XcmAssetTransfer? {
        guard
            let chain = chains.first(where: { $0.chainId == chainAssetId.chainId }),
            let xcmTransfers = chain.assets.first(where: { $0.assetId == chainAssetId.assetId })?.xcmTransfers else {
            return nil
        }

        return xcmTransfers.first { $0.destination.chainId == destinationChainId }
    }

    func destinationFee(
        from chainAssetId: ChainAssetId,
        to destinationChainId: ChainModel.Id
    ) -> XcmAssetTransferFee? {
        let transfer = transfer(from: chainAssetId, destinationChainId: destinationChainId)
        return transfer?.destination.fee
    }

    func reserveFee(from chainAssetId: ChainAssetId) -> XcmAssetTransferFee? {
        guard
            let assetLocationId = asset(from: chainAssetId)?.assetLocation,
            let assetLocation = assetLocation(for: assetLocationId) else {
            return nil
        }

        return try? assetLocation.reserveFee?.map(to: XcmAssetTransferFee.self, with: nil)
    }
}
