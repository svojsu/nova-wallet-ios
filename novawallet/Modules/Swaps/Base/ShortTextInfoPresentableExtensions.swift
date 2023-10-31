import SoraFoundation

extension ShortTextInfoPresentable {
    func showFeeInfo(from view: ControllerBackedProtocol?) {
        let title = LocalizableResource {
            R.string.localizable.commonNetwork(
                preferredLanguages: $0.rLanguages
            )
        }
        let details = LocalizableResource {
            R.string.localizable.swapsNetworkFeeDescription(
                preferredLanguages: $0.rLanguages
            )
        }
        showInfo(
            from: view,
            title: title,
            details: details
        )
    }

    func showRateInfo(from view: ControllerBackedProtocol?) {
        let title = LocalizableResource {
            R.string.localizable.swapsSetupDetailsRate(
                preferredLanguages: $0.rLanguages
            )
        }
        let details = LocalizableResource {
            R.string.localizable.swapsRateDescription(
                preferredLanguages: $0.rLanguages
            )
        }
        showInfo(
            from: view,
            title: title,
            details: details
        )
    }

    func showSlippageInfo(from view: ControllerBackedProtocol?) {
        let title = LocalizableResource {
            R.string.localizable.swapsSetupSlippage(preferredLanguages: $0.rLanguages)
        }
        let details = LocalizableResource {
            R.string.localizable.swapsSetupSlippageDescription(preferredLanguages: $0.rLanguages)
        }
        showInfo(
            from: view,
            title: title,
            details: details
        )
    }
}
