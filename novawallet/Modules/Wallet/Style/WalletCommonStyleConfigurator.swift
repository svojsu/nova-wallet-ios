import Foundation
import CommonWallet

struct WalletCommonStyleConfigurator {
    let navigationBarStyle: WalletNavigationBarStyleProtocol = {
        var navigationBarStyle = WalletNavigationBarStyle(
            barColor: .clear,
            shadowColor: .clear,
            itemTintColor: R.color.colorIconPrimary()!,
            titleColor: R.color.colorTextPrimary()!,
            titleFont: UIFont.h3Title,
            backButtonImage: R.image.iconBack()
        )
        return navigationBarStyle
    }()

    let accessoryStyle: WalletAccessoryStyleProtocol = {
        let title = WalletTextStyle(
            font: UIFont.p1Paragraph,
            color: R.color.colorTextPrimary()!
        )

        let buttonTitle = WalletTextStyle(
            font: UIFont.h5Title,
            color: R.color.colorTextPrimary()!
        )

        let buttonStyle = WalletRoundedButtonStyle(
            background: R.color.colorButtonBackgroundPrimary()!,
            title: buttonTitle
        )

        let separator = WalletStrokeStyle(color: .clear, lineWidth: 0.0)

        return WalletAccessoryStyle(
            title: title,
            action: buttonStyle,
            separator: separator,
            background: R.color.colorIconSecondary()!
        )
    }()
}

extension WalletCommonStyleConfigurator {
    func configure(builder: WalletStyleBuilderProtocol) {
        builder
            .with(background: R.color.colorBlack()!)
            .with(navigationBarStyle: navigationBarStyle)
            .with(header1: UIFont.h1Title)
            .with(header2: UIFont.h2Title)
            .with(header3: UIFont.h3Title)
            .with(header4: UIFont.h4Title)
            .with(bodyBold: UIFont.h5Title)
            .with(bodyRegular: UIFont.p1Paragraph)
            .with(small: UIFont.p2Paragraph)
            .with(keyboardIcon: R.image.iconKeyboardOff()!)
            .with(caretColor: R.color.colorIconPrimary()!)
            .with(closeIcon: R.image.iconClose())
            .with(shareIcon: R.image.iconShare())
            .with(accessoryStyle: accessoryStyle)
            .with(formCellStyle: WalletFormCellStyle.fearless)
    }
}
