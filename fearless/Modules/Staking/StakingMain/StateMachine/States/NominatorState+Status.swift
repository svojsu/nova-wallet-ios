import Foundation
import IrohaCrypto
import BigInt

extension NominatorState {
    var status: NominationViewStatus {
        guard let eraStakers = commonData.eraStakersInfo else {
            return .undefined
        }

        do {
            let accountId = try SS58AddressFactory().accountId(from: stashItem.stash)

            let allNominators = eraStakers.validators.map(\.exposure.others)
                .flatMap { (nominators) -> [IndividualExposure] in
                    if let maxNominatorsPerValidator = commonData.maxNominatorsPerValidator {
                        return Array(nominators.prefix(Int(maxNominatorsPerValidator)))
                    } else {
                        return nominators
                    }
                }
                .reduce(into: Set<Data>()) { $0.insert($1.who) }

            if allNominators.contains(accountId) {
                return .active(era: eraStakers.era)
            }

            if nomination.submittedIn >= eraStakers.era {
                return .waiting
            }

            return .inactive(era: eraStakers.era)

        } catch {
            return .undefined
        }
    }

    func createStatusPresentableViewModel(
        for minimumStake: BigUInt?,
        locale: Locale?
    ) -> AlertPresentableViewModel? {
        switch status {
        case .active:
            return createActiveStatus(for: minimumStake, locale: locale)
        case .inactive:
            return createInactiveStatus(for: minimumStake, locale: locale)
        case .waiting:
            return createWaitingStatus(for: minimumStake, locale: locale)
        case .undefined:
            return createUndefinedStatus(for: minimumStake, locale: locale)
        }
    }

    private func createActiveStatus(
        for _: BigUInt?,
        locale: Locale?
    ) -> AlertPresentableViewModel? {
        let closeAction = R.string.localizable.commonClose(preferredLanguages: locale?.rLanguages)
        let title = R.string.localizable
            .stakingNominatorStatusAlertActiveTitle(preferredLanguages: locale?.rLanguages)
        let message = R.string.localizable
            .stakingNominatorStatusAlertActiveMessage(preferredLanguages: locale?.rLanguages)

        return AlertPresentableViewModel(
            title: title,
            message: message,
            actions: [],
            closeAction: closeAction
        )
    }

    private func createInactiveStatus(
        for minimumStake: BigUInt?,
        locale: Locale?
    ) -> AlertPresentableViewModel? {
        guard let minimumStake = minimumStake else {
            return nil
        }

        let closeAction = R.string.localizable.commonClose(preferredLanguages: locale?.rLanguages)
        let title = R.string.localizable
            .stakingNominatorStatusAlertInactiveTitle(preferredLanguages: locale?.rLanguages)
        let message: String

        if ledgerInfo.active < minimumStake {
            message = R.string.localizable
                .stakingNominatorStatusAlertLowStake(preferredLanguages: locale?.rLanguages)
        } else {
            message = R.string.localizable
                .stakingNominatorStatusAlertNoValidators(preferredLanguages: locale?.rLanguages)
        }

        return AlertPresentableViewModel(
            title: title,
            message: message,
            actions: [],
            closeAction: closeAction
        )
    }

    private func createWaitingStatus(
        for _: BigUInt?,
        locale: Locale?
    ) -> AlertPresentableViewModel? {
        let closeAction = R.string.localizable.commonClose(preferredLanguages: locale?.rLanguages)
        let title = R.string.localizable
            .stakingNominatorStatusWaiting(preferredLanguages: locale?.rLanguages)
        let message = R.string.localizable
            .stakingNominatorStatusAlertWaitingMessage(preferredLanguages: locale?.rLanguages)

        return AlertPresentableViewModel(
            title: title,
            message: message,
            actions: [],
            closeAction: closeAction
        )
    }

    private func createElectionStatus(
        for _: BigUInt?,
        locale: Locale?
    ) -> AlertPresentableViewModel? {
        let closeAction = R.string.localizable.commonClose(preferredLanguages: locale?.rLanguages)
        let title = R.string.localizable
            .stakingNominatorStatusElection(preferredLanguages: locale?.rLanguages)
        let message = R.string.localizable
            .stakingNominatorStatusAlertElectionMessage(preferredLanguages: locale?.rLanguages)

        return AlertPresentableViewModel(
            title: title,
            message: message,
            actions: [],
            closeAction: closeAction
        )
    }

    private func createUndefinedStatus(
        for _: BigUInt?,
        locale _: Locale?
    ) -> AlertPresentableViewModel? {
        nil
    }
}
