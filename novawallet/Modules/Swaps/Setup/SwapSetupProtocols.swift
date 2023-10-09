import BigInt

protocol SwapSetupViewProtocol: ControllerBackedProtocol {
    func didReceiveButtonState(title: String, enabled: Bool)
    func didReceiveInputChainAsset(payViewModel viewModel: SwapAssetInputViewModel)
    func didReceiveAmount(payInputViewModel inputViewModel: AmountInputViewModelProtocol)
    func didReceiveAmountInputPrice(payViewModel: String?)
    func didReceiveTitle(payViewModel viewModel: TitleHorizontalMultiValueView.Model)
    func didReceiveInputChainAsset(receiveViewModel viewModel: SwapAssetInputViewModel)
    func didReceiveAmount(receiveInputViewModel inputViewModel: AmountInputViewModelProtocol)
    func didReceiveAmountInputPrice(receiveViewModel: String?)
    func didReceiveTitle(receiveViewModel viewModel: TitleHorizontalMultiValueView.Model)
    func didReceiveRate(viewModel: LoadableViewModelState<String>)
    func didReceiveNetworkFee(viewModel: LoadableViewModelState<BalanceViewModelProtocol>)
    func didReceiveDetailsState(isAvailable: Bool)
}

protocol SwapSetupPresenterProtocol: AnyObject {
    func setup()
    func selectPayToken()
    func selectReceiveToken()
    func proceed()
    func swap()
    func updatePayAmount(_ amount: Decimal?)
    func updateReceiveAmount(_ amount: Decimal?)
    func showFeeActions()
    func showFeeInfo()
    func showRateInfo()
}

protocol SwapSetupInteractorInputProtocol: AnyObject {
    func setup()
    func update(receiveChainAsset: ChainAsset)
    func update(payChainAsset: ChainAsset)
    func calculateQuote(for args: AssetConversion.QuoteArgs)
    func calculateFee(for quote: AssetConversion.Quote, slippage: SwapSlippage)
}

protocol SwapSetupInteractorOutputProtocol: AnyObject {
    func didReceive(quote: AssetConversion.Quote)
    func didReceive(fee: BigUInt?)
    func didReceive(error: SwapSetupError)
    func didReceive(price: PriceData?, priceId: AssetModel.PriceId)
}

protocol SwapSetupWireframeProtocol: AnyObject, AlertPresentable, CommonRetryable, ErrorPresentable {
    func showPayTokenSelection(
        from view: ControllerBackedProtocol?,
        completionHandler: @escaping (ChainAsset) -> Void
    )
    func showReceiveTokenSelection(
        from view: ControllerBackedProtocol?,
        completionHandler: @escaping (ChainAsset) -> Void
    )
}

enum SwapSetupError: Error {
    case quote(Error)
    case fetchFeeFailed(Error)
    case price(Error, AssetModel.PriceId)
}

struct SwapSlippage {
    let direction: AssetConversion.Direction
    let slippage: BigUInt
}
