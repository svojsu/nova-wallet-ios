import UIKit
import SoraUI
import SoraFoundation

class AccountInputView: BackgroundedContentControl {
    let textField: UITextField = {
        let textField = UITextField()
        textField.font = .regularSubheadline
        textField.textColor = R.color.colorWhite()
        textField.tintColor = R.color.colorWhite()
        textField.textAlignment = .left
        textField.clearButtonMode = .whileEditing

        textField.keyboardType = .default
        textField.returnKeyType = .done

        return textField
    }()

    let pasteButton: RoundedButton = {
        let button = RoundedButton()
        button.applyAccessoryStyle()
        button.contentInsets = UIEdgeInsets(top: 6.0, left: 12.0, bottom: 6.0, right: 12.0)
        button.imageWithTitleView?.titleFont = .semiBoldFootnote

        return button
    }()

    let scanButton: RoundedButton = {
        let button = RoundedButton()
        button.applyAccessoryStyle()

        let icon = R.image.iconTransferScan()?.tinted(with: R.color.colorAccent()!)
        button.imageWithTitleView?.iconImage = icon
        button.imageWithTitleView?.spacingBetweenLabelAndIcon = 0
        button.contentInsets = UIEdgeInsets(top: 6.0, left: 8.0, bottom: 6.0, right: 8.0)

        return button
    }()

    private let stackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 8.0
        view.axis = .horizontal
        view.alignment = .fill
        return view
    }()

    let pasteboardService = PasteboardHandler(pasteboard: UIPasteboard.general)

    var roundedBackgroundView: RoundedView? {
        backgroundView as? RoundedView
    }

    var iconSize = CGSize(width: 24.0, height: 24.0) {
        didSet {
            setNeedsLayout()
        }
    }

    let iconView: UIImageView = {
        let view = UIImageView()
        view.image = R.image.iconAddressPlaceholder()
        return view
    }()

    var locale = Locale.current {
        didSet {
            if oldValue != locale {
                setupLocalization()
            }
        }
    }

    private var fieldStateViewModel: AccountFieldStateViewModel?
    private var inputViewModel: InputViewModelProtocol?

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48.0)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

        configure()
        setupLocalization()
    }

    func bind(fieldStateViewModel: AccountFieldStateViewModel) {
        self.fieldStateViewModel?.icon?.cancel(on: iconView)
        self.fieldStateViewModel = fieldStateViewModel

        iconView.image = R.image.iconAddressPlaceholder()

        fieldStateViewModel.icon?.loadImage(on: iconView, targetSize: iconSize, animated: true)
    }

    func bind(inputViewModel: InputViewModelProtocol) {
        if textField.text != inputViewModel.inputHandler.value {
            textField.text = inputViewModel.inputHandler.value
        }

        self.inputViewModel = inputViewModel
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView?.frame = bounds

        layoutContent()
    }

    private func setupLocalization() {
        let placeholder = R.string.localizable.commonAddress(preferredLanguages: locale.rLanguages)

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: R.color.colorWhite32()!,
                .font: UIFont.regularSubheadline
            ]
        )

        pasteButton.imageWithTitleView?.title = R.string.localizable.commonPaste(
            preferredLanguages: locale.rLanguages
        )

        setNeedsLayout()
    }

    private func layoutContent() {
        iconView.frame = CGRect(
            origin: CGPoint(
                x: bounds.minX + contentInsets.left,
                y: bounds.midY - iconSize.height / 2.0
            ),
            size: iconSize
        )

        let buttonHeight: CGFloat = 32.0
        var actionsWidth: CGFloat = 0

        if !pasteButton.isHidden {
            actionsWidth += pasteButton.intrinsicContentSize.width
        }

        if !scanButton.isHidden {
            actionsWidth += !pasteButton.isHidden ? stackView.spacing : 0
            actionsWidth += scanButton.intrinsicContentSize.width
        }

        stackView.frame = CGRect(
            x: bounds.maxX - contentInsets.right - actionsWidth,
            y: bounds.midY - buttonHeight / 2.0,
            width: actionsWidth,
            height: buttonHeight
        )

        let fieldSpacing: CGFloat = 12.0
        let fieldWidth: CGFloat

        if actionsWidth > 0 {
            fieldWidth = max(stackView.frame.minX - iconView.frame.maxX - 2 * fieldSpacing, 0)
        } else {
            fieldWidth = max(stackView.frame.minX - iconView.frame.maxX - fieldSpacing, 0)
        }

        let fieldHeight = textField.intrinsicContentSize.height

        textField.frame = CGRect(
            x: iconView.frame.maxX + fieldSpacing,
            y: bounds.midY - fieldHeight / 2.0,
            width: fieldWidth,
            height: fieldHeight
        )
    }

    // MARK: Configure

    private func configure() {
        backgroundColor = UIColor.clear

        configureBackgroundViewIfNeeded()
        configureContentViewIfNeeded()
        configureTextFieldHandlers()
        configurePasteHandlers()

        updatePasteButtonState()
    }

    private func configureBackgroundViewIfNeeded() {
        if backgroundView == nil {
            let roundedView = RoundedView()
            roundedView.isUserInteractionEnabled = false
            roundedView.shadowOpacity = 0.0
            roundedView.strokeColor = R.color.colorAccent()!
            roundedView.fillColor = R.color.colorWhite8()!
            roundedView.highlightedFillColor = R.color.colorWhite8()!
            roundedView.strokeWidth = 0.0
            roundedView.cornerRadius = 12.0

            backgroundView = roundedView
        }
    }

    private func configureContentViewIfNeeded() {
        if contentView == nil {
            let contentView = UIView()
            contentView.backgroundColor = .clear
            contentView.isUserInteractionEnabled = false
            self.contentView = contentView
        }

        contentView?.addSubview(iconView)

        addSubview(textField)

        stackView.addArrangedSubview(pasteButton)
        stackView.addArrangedSubview(scanButton)

        addSubview(stackView)

        contentInsets = UIEdgeInsets(top: 8.0, left: 12.0, bottom: 8.0, right: 12.0)
    }

    private func configureTextFieldHandlers() {
        textField.addTarget(self, action: #selector(actionEditingBeginEnd), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(actionEditingBeginEnd), for: .editingDidEnd)
        textField.addTarget(
            self,
            action: #selector(actionEditingChanged(_:)),
            for: .editingChanged
        )

        textField.delegate = self
    }

    private func configurePasteHandlers() {
        pasteButton.addTarget(self, action: #selector(actionPaste), for: .touchUpInside)

        pasteboardService.delegate = self
    }

    private func updatePasteButtonState() {
        if pasteboardService.pasteboard.hasStrings, !textField.isFirstResponder {
            pasteButton.isHidden = false
        } else {
            pasteButton.isHidden = true
        }
    }

    // MARK: Action

    @objc private func actionEditingChanged(_ sender: UITextField) {
        if inputViewModel?.inputHandler.value != sender.text {
            sender.text = inputViewModel?.inputHandler.value
        }

        sendActions(for: .editingChanged)
    }

    @objc private func actionEditingBeginEnd() {
        if textField.isFirstResponder {
            roundedBackgroundView?.strokeWidth = 0.5

            scanButton.isHidden = true
        } else {
            roundedBackgroundView?.strokeWidth = 0.0

            scanButton.isHidden = false
        }

        updatePasteButtonState()

        setNeedsLayout()
    }

    @objc func actionPaste() {
        if
            let pasteString = pasteboardService.pasteboard.string,
            let inputViewModel = inputViewModel,
            inputViewModel.inputHandler.value != pasteString {
            let currentValue = inputViewModel.inputHandler.value as NSString
            let currentLength = currentValue.length
            let range = NSRange(location: 0, length: currentLength)

            if inputViewModel.inputHandler.didReceiveReplacement(pasteString, for: range) {
                textField.text = pasteString
                sendActions(for: .editingChanged)
            }
        }
    }
}

extension AccountInputView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let inputViewModel = inputViewModel else {
            return true
        }

        let shouldApply = inputViewModel.inputHandler.didReceiveReplacement(string, for: range)

        if !shouldApply, textField.text != inputViewModel.inputHandler.value {
            textField.text = inputViewModel.inputHandler.value
        }

        return shouldApply
    }

    func textFieldShouldClear(_: UITextField) -> Bool {
        inputViewModel?.inputHandler.changeValue(to: "")

        return true
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension AccountInputView: PasteboardHandlerDelegate {
    func didReceivePasteboardChange(notification _: Notification) {
        updatePasteButtonState()
    }

    func didReceivePasteboardRemove(notification _: Notification) {
        updatePasteButtonState()
    }
}
