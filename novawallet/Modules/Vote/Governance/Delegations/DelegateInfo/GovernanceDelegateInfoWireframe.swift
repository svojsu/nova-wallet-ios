import Foundation

final class GovernanceDelegateInfoWireframe: GovernanceDelegateInfoWireframeProtocol {
    let state: GovernanceSharedState

    init(state: GovernanceSharedState) {
        self.state = state
    }

    func showFullDescription(
        from view: GovernanceDelegateInfoViewProtocol?,
        name: String,
        longDescription: String
    ) {
        guard let view = view,
              let navigationController = view.controller.navigationController else {
            return
        }

        let state = DelegateInfoDetailsState(name: name, longDescription: longDescription)
        let delegateInfoDetailsViewController = DelegateInfoDetailsViewFactory.createView(state: state)

        navigationController.pushViewController(
            delegateInfoDetailsViewController.controller,
            animated: true
        )
    }

    func showDelegations(
        from view: GovernanceDelegateInfoViewProtocol?,
        delegateAddress: AccountAddress
    ) {
        guard let delegationListView = DelegationListViewFactory.createView(
            accountAddress: delegateAddress,
            state: state
        ) else {
            return
        }

        view?.controller.navigationController?.pushViewController(
            delegationListView.controller,
            animated: true
        )
    }

    func showRecentVotes(
        from _: GovernanceDelegateInfoViewProtocol?,
        delegateAddress _: AccountAddress
    ) {
        // TODO: Task #860pmdtg6
    }

    func showAllVotes(
        from _: GovernanceDelegateInfoViewProtocol?,
        delegateAddress _: AccountAddress
    ) {
        // TODO: Task #860pmdtg6
    }

    func showAddDelegation(
        from view: GovernanceDelegateInfoViewProtocol?,
        delegate: GovernanceDelegateFlowDisplayInfo<AccountId>
    ) {
        guard
            let tracksView = GovernanceAddDelegationTracksViewFactory.createView(
                for: state,
                delegate: delegate
            ) else {
            return
        }

        view?.controller.navigationController?.pushViewController(
            tracksView.controller,
            animated: true
        )
    }

    func showTracks(
        from _: GovernanceDelegateInfoViewProtocol?,
        tracks _: [GovernanceTrackInfoLocal],
        delegations _: [TrackIdLocal: ReferendumDelegatingLocal]
    ) {}

    func showEditDelegation(from _: GovernanceDelegateInfoViewProtocol?) {}

    func showRevokeDelegation(from _: GovernanceDelegateInfoViewProtocol?) {}
}
