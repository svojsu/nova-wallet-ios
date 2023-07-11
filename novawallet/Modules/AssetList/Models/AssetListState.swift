import Foundation
import BigInt

struct AssetListState {
    let priceResult: Result<[ChainAssetId: PriceData], Error>?
    let balanceResults: [ChainAssetId: Result<BigUInt, Error>]
    let allChains: [ChainModel.Id: ChainModel]
    let crowdloansResult: Result<[ChainModel.Id: [CrowdloanContributionData]], Error>?

    init(
        priceResult: Result<[ChainAssetId: PriceData], Error>? = nil,
        balanceResults: [ChainAssetId: Result<BigUInt, Error>] = [:],
        allChains: [ChainModel.Id: ChainModel] = [:],
        crowdloansResult: Result<[ChainModel.Id: [CrowdloanContributionData]], Error>? = nil
    ) {
        self.priceResult = priceResult
        self.balanceResults = balanceResults
        self.allChains = allChains
        self.crowdloansResult = crowdloansResult
    }

    init(model: AssetListBuilderResult.Model) {
        priceResult = model.priceResult
        balanceResults = model.balanceResults
        allChains = model.allChains
        crowdloansResult = model.crowdloansResult
    }

    func chainAsset(for chainAssetId: ChainAssetId) -> ChainAsset? {
        let chainId = chainAssetId.chainId
        let assetId = chainAssetId.assetId

        guard let chain = allChains[chainId],
              let asset = chain.assets.first(where: { $0.assetId == assetId }) else {
            return nil
        }

        return .init(chain: chain, asset: asset)
    }
}

typealias AssetListStateObservable = Observable<NotEqualWrapper<AssetListState>>
