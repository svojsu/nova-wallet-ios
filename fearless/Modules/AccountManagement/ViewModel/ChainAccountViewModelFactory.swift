import Foundation
import SubstrateSdk
import UIKit

protocol ChainAccountViewModelFactoryProtocol {
    func createViewModel(
        from _: MetaAccountModel,
        chains: [ChainModel.Id: ChainModel],
        for locale: Locale
    ) -> ChainAccountListViewModel
}

final class ChainAccountViewModelFactory {
    let iconGenerator: IconGenerating

    init(iconGenerator: IconGenerating) {
        self.iconGenerator = iconGenerator
    }

    private func createCustomSecretAccountList(
        from wallet: MetaAccountModel,
        chains: [ChainModel.Id: ChainModel],
        for locale: Locale
    ) -> [ChainAccountViewModelItem] {
        wallet.chainAccounts.compactMap { chainAccount in
            guard let chainModel = chains[chainAccount.chainId] else {
                return nil
            }

            let chainName = chainModel.name

            let accountAddress: String?
            let icon: DrawableIcon?

            if let accountResponse = wallet.fetch(for: chainModel.accountRequest()) {
                accountAddress = try? accountResponse.accountId.toAddress(using: chainModel.chainFormat)
                icon = try? iconGenerator.generateFromAccountId(accountResponse.accountId)
            } else {
                accountAddress = nil
                icon = nil
            }

            return ChainAccountViewModelItem(
                chainId: chainAccount.chainId,
                name: chainName,
                address: accountAddress,
                warning: R.string.localizable.accountNotFoundCaption(preferredLanguages: locale.rLanguages),
                chainIconViewModel: RemoteImageViewModel(url: chainModel.icon),
                accountIcon: icon
            )
        }.sorted { first, second in
            first.name < second.name
        }
    }

    private func createSharedSecretAccountList(
        from wallet: MetaAccountModel,
        chains: [ChainModel.Id: ChainModel],
        for locale: Locale
    ) -> [ChainAccountViewModelItem] {
        chains.compactMap { (chainId: ChainModel.Id, chainModel: ChainModel) in
            guard wallet.chainAccounts.first(where: { chainAccountModel in
                chainAccountModel.chainId == chainId
            }) == nil else { return nil }

            let chainName = chainModel.name

            let accountAddress: String?
            let icon: DrawableIcon?

            if let accountResponse = wallet.fetch(for: chainModel.accountRequest()) {
                accountAddress = try? accountResponse.accountId.toAddress(using: chainModel.chainFormat)
                icon = try? iconGenerator.generateFromAccountId(accountResponse.accountId)
            } else {
                accountAddress = nil
                icon = nil
            }

            return ChainAccountViewModelItem(
                chainId: chainId,
                name: chainName,
                address: accountAddress,
                warning: R.string.localizable.accountNotFoundCaption(preferredLanguages: locale.rLanguages),
                chainIconViewModel: RemoteImageViewModel(url: chainModel.icon),
                accountIcon: icon
            )
        }.sorted { first, second in
            guard first.address != nil, second.address != nil else {
                return first.address == nil
            }

            return first.name < second.name
        }
    }
}

extension ChainAccountViewModelFactory: ChainAccountViewModelFactoryProtocol {
    func createViewModel(
        from wallet: MetaAccountModel,
        chains: [ChainModel.Id: ChainModel],
        for locale: Locale
    ) -> ChainAccountListViewModel {
        let customSecretAccountList = createCustomSecretAccountList(from: wallet, chains: chains, for: locale)
        let sharedSecretAccountList = createSharedSecretAccountList(from: wallet, chains: chains, for: locale)

        guard !customSecretAccountList.isEmpty else {
            return [ChainAccountListSectionViewModel(
                section: .sharedSecret,
                chainAccounts: sharedSecretAccountList
            )]
        }

        return [
            ChainAccountListSectionViewModel(
                section: .customSecret,
                chainAccounts: customSecretAccountList
            ),
            ChainAccountListSectionViewModel(
                section: .sharedSecret,
                chainAccounts: sharedSecretAccountList
            )
        ]
    }
}
