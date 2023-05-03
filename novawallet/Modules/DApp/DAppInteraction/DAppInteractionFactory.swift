import Foundation

final class DAppInteractionFactory {
    static func createMediator() -> DAppInteractionMediating {
        let logger = Logger.shared

        let presenter = DAppInteractionPresenter(logger: logger)

        let storageFacade = UserDataStorageFacade.shared
        let accountRepositoryFactory = AccountRepositoryFactory(storageFacade: storageFacade)
        let settingsRepository = accountRepositoryFactory.createAuthorizedDAppsRepository(for: nil)
        let walletsRepository = accountRepositoryFactory.createMetaAccountRepository(
            for: nil,
            sortDescriptors: []
        )

        let phishingVerifier = PhishingSiteVerifier.createSequentialVerifier()

        let chainsStore = ChainsStore(chainRegistry: ChainRegistryFacade.sharedRegistry)

        let walletConnect = WalletConnectServiceFactory.createInteractor(
            chainsStore: chainsStore,
            settingsRepository: settingsRepository,
            walletsRepository: walletsRepository,
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )

        let mediator = DAppInteractionMediator(
            presenter: presenter,
            children: [walletConnect],
            chainsStore: chainsStore,
            settingsRepository: settingsRepository,
            securedLayer: SecurityLayerService.shared,
            sequentialPhishingVerifier: phishingVerifier,
            operationQueue: OperationManagerFacade.sharedDefaultQueue,
            logger: logger
        )

        presenter.interactor = mediator
        walletConnect.mediator = mediator

        return mediator
    }
}
