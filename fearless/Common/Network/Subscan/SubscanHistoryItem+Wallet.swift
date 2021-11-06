import Foundation
import CommonWallet
import IrohaCrypto

extension SubscanRewardItemData: WalletRemoteHistoryItemProtocol {
    var identifier: String { "\(recordId)-\(eventIndex)" }
    var itemBlockNumber: UInt64 { blockNumber }
    var itemExtrinsicIndex: UInt16 { extrinsicIndex }
    var itemTimestamp: Int64 { timestamp }
    var label: WalletRemoteHistorySourceLabel { .rewards }

    func createTransactionForAddress(
        _ address: String,
        assetId: String,
        chainAssetInfo: ChainAssetDisplayInfo
    ) -> AssetTransactionData {
        AssetTransactionData.createTransaction(
            from: self,
            address: address,
            assetId: assetId,
            chainAssetInfo: chainAssetInfo
        )
    }
}

extension SubscanTransferItemData: WalletRemoteHistoryItemProtocol {
    var identifier: String { hash }
    var itemBlockNumber: UInt64 { blockNumber }
    var itemExtrinsicIndex: UInt16 { extrinsicIndex.value }
    var itemTimestamp: Int64 { timestamp }
    var label: WalletRemoteHistorySourceLabel { .transfers }

    func createTransactionForAddress(
        _ address: String,
        assetId: String,
        chainAssetInfo: ChainAssetDisplayInfo
    ) -> AssetTransactionData {
        AssetTransactionData.createTransaction(
            from: self,
            address: address,
            assetId: assetId,
            chainAssetInfo: chainAssetInfo
        )
    }
}

extension SubscanConcreteExtrinsicsItemData: WalletRemoteHistoryItemProtocol {
    var identifier: String { hash }
    var itemBlockNumber: UInt64 { blockNumber }
    var itemExtrinsicIndex: UInt16 { extrinsicIndex.value }
    var itemTimestamp: Int64 { timestamp }
    var label: WalletRemoteHistorySourceLabel { .extrinsics }

    func createTransactionForAddress(
        _ address: String,
        assetId: String,
        chainAssetInfo: ChainAssetDisplayInfo
    ) -> AssetTransactionData {
        AssetTransactionData.createTransaction(
            from: self,
            address: address,
            assetId: assetId,
            chainAssetInfo: chainAssetInfo
        )
    }
}