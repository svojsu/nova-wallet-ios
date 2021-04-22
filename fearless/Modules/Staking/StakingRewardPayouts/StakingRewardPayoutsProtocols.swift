import SoraFoundation
import SoraUI

protocol StakingRewardPayoutsViewProtocol: ControllerBackedProtocol,
    Localizable,
    LoadableViewProtocol {
    func reload(with state: StakingRewardPayoutsViewState)
}

enum StakingRewardPayoutsViewState {
    case loading(Bool)
    case payoutsList(LocalizableResource<StakingPayoutViewModel>)
    case emptyList
    case error(LocalizableResource<String>)
}

protocol StakingRewardPayoutsPresenterProtocol: AnyObject {
    func setup()
    func handleSelectedHistory(at index: Int)
    func handlePayoutAction()
    func reload()
}

protocol StakingRewardPayoutsInteractorInputProtocol: AnyObject {
    func setup()
    func reload()
}

protocol StakingRewardPayoutsInteractorOutputProtocol: AnyObject {
    func didReceive(result: Result<PayoutsInfo, PayoutRewardsServiceError>)
    func didReceive(priceResult: Result<PriceData?, Error>)
}

protocol StakingRewardPayoutsWireframeProtocol: AnyObject {
    func showRewardDetails(
        from view: ControllerBackedProtocol?,
        payoutInfo: PayoutInfo,
        activeEra: EraIndex,
        historyDepth: UInt32,
        chain: Chain
    )

    func showPayoutConfirmation(
        for payouts: [PayoutInfo],
        from view: ControllerBackedProtocol?
    )
}

protocol StakingRewardPayoutsViewFactoryProtocol: AnyObject {
    static func createViewForNominator(stashAddress: AccountAddress) -> StakingRewardPayoutsViewProtocol?
    static func createViewForValidator(stashAddress: AccountAddress) -> StakingRewardPayoutsViewProtocol?
}

protocol StakingPayoutViewModelFactoryProtocol {
    func createPayoutsViewModel(
        payoutsInfo: PayoutsInfo,
        priceData: PriceData?
    ) -> LocalizableResource<StakingPayoutViewModel>
}