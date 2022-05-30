import UIKit
import CommonWallet
import SoraFoundation

final class ParaStkStakeSetupViewController: UIViewController, ViewHolder {
    typealias RootViewType = ParaStkStakeSetupViewLayout

    let presenter: ParaStkStakeSetupPresenterProtocol

    private var collatorViewModel: DisplayAddressViewModel?

    init(presenter: ParaStkStakeSetupPresenterProtocol, localizationManager: LocalizationManagerProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = ParaStkStakeSetupViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLocalization()
        setupHandlers()

        updateActionButtonState()

        presenter.setup()
    }

    private func setupLocalization() {
        let languages = selectedLocale.rLanguages

        setupAmountInputAccessoryView()

        rootView.collatorTitleLabel.text = R.string.localizable.parachainStakingCollator(
            preferredLanguages: languages
        )

        applyCollatorTitle(viewModel: collatorViewModel)

        rootView.amountView.titleView.text = R.string.localizable.walletSendAmountTitle(
            preferredLanguages: languages
        )

        rootView.amountView.detailsTitleLabel.text = R.string.localizable.commonTransferablePrefix(
            preferredLanguages: languages
        )

        rootView.rewardsView.titleLabel.text = R.string.localizable.parachainStakingTransferrableRewards(
            preferredLanguages: languages
        )

        rootView.minStakeView.titleLabel.text = R.string.localizable.parachainStakingMinimumStake(
            preferredLanguages: languages
        )

        rootView.networkFeeView.locale = selectedLocale

        updateActionButtonState()
    }

    private func updateActionButtonState() {
        if collatorViewModel == nil {
            rootView.actionButton.applyDisabledStyle()
            rootView.actionButton.isUserInteractionEnabled = false

            rootView.actionButton.imageWithTitleView?.title = R.string.localizable
                .parachainStakingHintSelectCollator(preferredLanguages: selectedLocale.rLanguages)
            rootView.actionButton.invalidateLayout()

            return
        }

        if !rootView.amountInputView.completed {
            rootView.actionButton.applyDisabledStyle()
            rootView.actionButton.isUserInteractionEnabled = false

            rootView.actionButton.imageWithTitleView?.title = R.string.localizable
                .transferSetupEnterAmount(preferredLanguages: selectedLocale.rLanguages)
            rootView.actionButton.invalidateLayout()

            return
        }

        rootView.actionButton.applyEnabledStyle()
        rootView.actionButton.isUserInteractionEnabled = true

        rootView.actionButton.imageWithTitleView?.title = R.string.localizable.commonContinue(
            preferredLanguages: selectedLocale.rLanguages
        )
        rootView.actionButton.invalidateLayout()
    }

    private func applyAssetBalance(viewModel: AssetBalanceViewModelProtocol) {
        let assetViewModel = AssetViewModel(
            symbol: viewModel.symbol,
            imageViewModel: viewModel.iconViewModel
        )

        rootView.amountInputView.bind(assetViewModel: assetViewModel)
        rootView.amountInputView.bind(priceViewModel: viewModel.price)

        rootView.amountView.detailsValueLabel.text = viewModel.balance

        title = R.string.localizable.stakingStakeFormat(
            viewModel.symbol,
            preferredLanguages: selectedLocale.rLanguages
        )
    }

    private func stopCollatorLoading() {
        collatorViewModel?.imageViewModel?.cancel(on: rootView.collatorActionView.imageView)
    }

    private func applyCollatorImage(viewModel: DisplayAddressViewModel?) {
        if let viewModel = viewModel {
            viewModel.imageViewModel?.loadImage(
                on: rootView.collatorActionView.imageView,
                targetSize: UIConstants.address24IconSize,
                animated: true
            )
        } else {
            rootView.collatorActionView.imageView.image = R.image.iconAddressPlaceholder()
        }
    }

    private func applyCollatorTitle(viewModel: DisplayAddressViewModel?) {
        if let viewModel = viewModel {
            rootView.collatorActionView.titleLabel.lineBreakMode = viewModel.lineBreakMode
            rootView.collatorActionView.titleLabel.text = viewModel.name ?? viewModel.address
        } else {
            rootView.collatorActionView.titleLabel.lineBreakMode = .byTruncatingTail
            rootView.collatorActionView.titleLabel.text = R.string.localizable.parachainStakingSelectCollator(
                preferredLanguages: selectedLocale.rLanguages
            )
        }
    }

    private func applyRewards(viewModel: StakingRewardInfoViewModel) {
        rootView.rewardsView.priceLabel.text = viewModel.amountViewModel.price
        rootView.rewardsView.incomeLabel.text = viewModel.returnPercentage
        rootView.rewardsView.amountLabel.text = R.string.localizable.parachainStakingRewardsFormat(
            viewModel.amountViewModel.amount,
            preferredLanguages: selectedLocale.rLanguages
        )

        rootView.rewardsView.setNeedsLayout()
    }

    private func setupAmountInputAccessoryView() {
        let accessoryView = UIFactory.default.createAmountAccessoryView(
            for: self,
            locale: selectedLocale
        )

        rootView.amountInputView.textField.inputAccessoryView = accessoryView
    }

    private func setupHandlers() {
        rootView.collatorActionView.addTarget(
            self,
            action: #selector(actionSelectCollator),
            for: .touchUpInside
        )

        rootView.amountInputView.addTarget(
            self,
            action: #selector(actionAmountChange),
            for: .editingChanged
        )

        rootView.actionButton.addTarget(
            self,
            action: #selector(actionProceed),
            for: .touchUpInside
        )
    }

    @objc func actionAmountChange() {
        let amount = rootView.amountInputView.inputViewModel?.decimalAmount
        presenter.updateAmount(amount)

        updateActionButtonState()
    }

    @objc func actionSelectCollator() {
        presenter.selectCollator()
    }

    @objc func actionProceed() {
        presenter.proceed()
    }
}

extension ParaStkStakeSetupViewController: ParaStkStakeSetupViewProtocol {
    func didReceiveCollator(viewModel: DisplayAddressViewModel?) {
        stopCollatorLoading()

        collatorViewModel = viewModel

        applyCollatorImage(viewModel: viewModel)
        applyCollatorTitle(viewModel: viewModel)

        updateActionButtonState()
    }

    func didReceiveAssetBalance(viewModel: AssetBalanceViewModelProtocol) {
        applyAssetBalance(viewModel: viewModel)
    }

    func didReceiveFee(viewModel: BalanceViewModelProtocol?) {
        rootView.networkFeeView.bind(viewModel: viewModel)
    }

    func didReceiveAmount(inputViewModel: AmountInputViewModelProtocol) {
        rootView.amountInputView.bind(inputViewModel: inputViewModel)

        updateActionButtonState()
    }

    func didReceiveMinStake(viewModel: BalanceViewModelProtocol?) {
        rootView.minStakeView.bind(viewModel: viewModel)
    }

    func didReceiveReward(viewModel: StakingRewardInfoViewModel) {
        applyRewards(viewModel: viewModel)
    }
}

extension ParaStkStakeSetupViewController: AmountInputAccessoryViewDelegate {
    func didSelect(on _: AmountInputAccessoryView, percentage: Float) {
        rootView.amountInputView.textField.resignFirstResponder()

        presenter.selectAmountPercentage(percentage)
    }

    func didSelectDone(on _: AmountInputAccessoryView) {
        rootView.amountInputView.textField.resignFirstResponder()
    }
}

extension ParaStkStakeSetupViewController: Localizable {
    func applyLocalization() {
        if isViewLoaded {
            setupLocalization()
        }
    }
}