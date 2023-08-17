import Foundation
import SoraFoundation
import BigInt
import SoraKeystore

struct NetworkInfoViewModelParams {
    let minNominatorBond: BigUInt?
    let votersCount: UInt32?
}

struct NPoolsDetailsInfoParams {
    let totalActiveStake: BigUInt?
    let minStake: BigUInt?
    let duration: StakingDuration?
}

protocol NetworkInfoViewModelFactoryProtocol {
    func createNetworkStakingInfoViewModel(
        with networkStakingInfo: NetworkStakingInfo,
        chainAsset: ChainAsset,
        params: NetworkInfoViewModelParams,
        priceData: PriceData?
    ) -> LocalizableResource<NetworkStakingInfoViewModel>

    func createNPoolsStakingInfoViewModel(
        for params: NPoolsDetailsInfoParams,
        chainAsset: ChainAsset,
        priceData: PriceData?
    ) -> LocalizableResource<NetworkStakingInfoViewModel>?
}

final class NetworkInfoViewModelFactory {
    private var chainAsset: ChainAsset?
    private var balanceViewModelFactory: BalanceViewModelFactoryProtocol?
    private let priceAssetInfoFactory: PriceAssetInfoFactoryProtocol

    init(priceAssetInfoFactory: PriceAssetInfoFactoryProtocol) {
        self.priceAssetInfoFactory = priceAssetInfoFactory
    }

    private func getBalanceViewModelFactory(for chainAsset: ChainAsset) -> BalanceViewModelFactoryProtocol {
        if let factory = balanceViewModelFactory, self.chainAsset == chainAsset {
            return factory
        }

        let factory = BalanceViewModelFactory(
            targetAssetInfo: chainAsset.assetDisplayInfo,
            priceAssetInfoFactory: priceAssetInfoFactory
        )

        self.chainAsset = chainAsset
        balanceViewModelFactory = factory

        return factory
    }

    private func createStakeViewModel(
        stake: BigUInt,
        chainAsset: ChainAsset,
        priceData: PriceData?
    ) -> LocalizableResource<BalanceViewModelProtocol> {
        let balanceViewModelFactory = getBalanceViewModelFactory(for: chainAsset)

        let stakedAmount = Decimal.fromSubstrateAmount(
            stake,
            precision: Int16(chainAsset.asset.precision)
        ) ?? 0.0

        let stakedPair = balanceViewModelFactory.balanceFromPrice(
            stakedAmount,
            priceData: priceData,
            roundingMode: .up
        )

        return LocalizableResource { locale in
            stakedPair.value(for: locale)
        }
    }

    private func createTotalStakeViewModel(
        with networkStakingInfo: NetworkStakingInfo,
        chainAsset: ChainAsset,
        priceData: PriceData?
    ) -> LocalizableResource<BalanceViewModelProtocol> {
        createStakeViewModel(
            stake: networkStakingInfo.totalStake,
            chainAsset: chainAsset,
            priceData: priceData
        )
    }

    private func createMinimalStakeViewModel(
        with networkStakingInfo: NetworkStakingInfo,
        chainAsset: ChainAsset,
        minNominatorBond: BigUInt?,
        votersCount: UInt32?,
        priceData: PriceData?
    ) -> LocalizableResource<BalanceViewModelProtocol> {
        let minStake = networkStakingInfo.calculateMinimumStake(given: minNominatorBond, votersCount: votersCount)

        return createStakeViewModel(
            stake: minStake,
            chainAsset: chainAsset,
            priceData: priceData
        )
    }

    private func createActiveNominatorsViewModel(
        with networkStakingInfo: NetworkStakingInfo
    ) -> LocalizableResource<String> {
        LocalizableResource { locale in
            let quantityFormatter = NumberFormatter.quantity.localizableResource().value(for: locale)

            return quantityFormatter
                .string(from: networkStakingInfo.activeNominatorsCount as NSNumber) ?? ""
        }
    }

    private func createLockUpPeriodViewModel(
        with networkStakingInfo: NetworkStakingInfo
    ) -> LocalizableResource<String> {
        networkStakingInfo.stakingDuration.localizableUnlockingString
    }

    private func createStakingPeriod() -> LocalizableResource<String> {
        LocalizableResource { locale in
            R.string.localizable.stakingNetworkInfoStakingPeriodValue(
                preferredLanguages: locale.rLanguages
            )
        }
    }
}

extension NetworkInfoViewModelFactory: NetworkInfoViewModelFactoryProtocol {
    func createNetworkStakingInfoViewModel(
        with networkStakingInfo: NetworkStakingInfo,
        chainAsset: ChainAsset,
        params: NetworkInfoViewModelParams,
        priceData: PriceData?
    ) -> LocalizableResource<NetworkStakingInfoViewModel> {
        let localizedTotalStake = createTotalStakeViewModel(
            with: networkStakingInfo,
            chainAsset: chainAsset,
            priceData: priceData
        )

        let localizedMinimalStake = createMinimalStakeViewModel(
            with: networkStakingInfo,
            chainAsset: chainAsset,
            minNominatorBond: params.minNominatorBond,
            votersCount: params.votersCount,
            priceData: priceData
        )

        let nominatorsCount = createActiveNominatorsViewModel(with: networkStakingInfo)

        let localizedLockUpPeriod = createLockUpPeriodViewModel(with: networkStakingInfo)

        let stakingPeriod = createStakingPeriod()

        return LocalizableResource { locale in
            NetworkStakingInfoViewModel(
                totalStake: localizedTotalStake.value(for: locale),
                minimalStake: localizedMinimalStake.value(for: locale),
                activeNominators: nominatorsCount.value(for: locale),
                stakingPeriod: stakingPeriod.value(for: locale),
                lockUpPeriod: localizedLockUpPeriod.value(for: locale)
            )
        }
    }

    func createNPoolsStakingInfoViewModel(
        for params: NPoolsDetailsInfoParams,
        chainAsset: ChainAsset,
        priceData: PriceData?
    ) -> LocalizableResource<NetworkStakingInfoViewModel>? {
        let localizedTotalStake = params.totalActiveStake.map { totalStake in
            createStakeViewModel(
                stake: totalStake,
                chainAsset: chainAsset,
                priceData: priceData
            )
        }

        let localizedMinimalStake = params.minStake.map { minStake in
            createStakeViewModel(
                stake: minStake,
                chainAsset: chainAsset,
                priceData: priceData
            )
        }

        let localizedLockUpPeriod = params.duration?.localizableUnlockingString

        let stakingPeriod = createStakingPeriod()

        return LocalizableResource { locale in
            NetworkStakingInfoViewModel(
                totalStake: localizedTotalStake?.value(for: locale),
                minimalStake: localizedMinimalStake?.value(for: locale),
                activeNominators: nil,
                stakingPeriod: stakingPeriod.value(for: locale),
                lockUpPeriod: localizedLockUpPeriod?.value(for: locale)
            )
        }
    }
}
