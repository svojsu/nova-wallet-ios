import Foundation
import RobinHood

final class DAppListInteractor {
    weak var presenter: DAppListInteractorOutputProtocol?

    let walletSettings: SelectedWalletSettings
    let eventCenter: EventCenterProtocol
    let dAppProvider: AnySingleValueProvider<DAppList>
    let dAppsLocalSubscriptionFactory: DAppLocalSubscriptionFactoryProtocol
    let dAppsFavoriteRepository: AnyDataProviderRepository<DAppFavorite>
    let phishingSyncService: ApplicationServiceProtocol
    let operationQueue: OperationQueue
    let logger: LoggerProtocol
    let proxyListLocalSubscriptionFactory: ProxyListLocalSubscriptionFactoryProtocol

    private var favoriteDAppsProvider: StreamableProvider<DAppFavorite>?
    private var proxyListSubscription: StreamableProvider<ProxyAccountModel>?
    private var proxies: [ProxyAccountModel] = []

    init(
        walletSettings: SelectedWalletSettings,
        eventCenter: EventCenterProtocol,
        dAppProvider: AnySingleValueProvider<DAppList>,
        phishingSyncService: ApplicationServiceProtocol,
        dAppsLocalSubscriptionFactory: DAppLocalSubscriptionFactoryProtocol,
        dAppsFavoriteRepository: AnyDataProviderRepository<DAppFavorite>,
        proxyListLocalSubscriptionFactory: ProxyListLocalSubscriptionFactoryProtocol,
        operationQueue: OperationQueue,
        logger: LoggerProtocol
    ) {
        self.walletSettings = walletSettings
        self.eventCenter = eventCenter
        self.dAppProvider = dAppProvider
        self.phishingSyncService = phishingSyncService
        self.dAppsLocalSubscriptionFactory = dAppsLocalSubscriptionFactory
        self.dAppsFavoriteRepository = dAppsFavoriteRepository
        self.proxyListLocalSubscriptionFactory = proxyListLocalSubscriptionFactory
        self.operationQueue = operationQueue
        self.logger = logger
    }

    deinit {
        phishingSyncService.throttle()
    }

    private func provideWallet() {
        guard let wallet = walletSettings.value else {
            return
        }

        presenter?.didReceive(walletResult: .success(wallet))
    }

    private func provideWalletUpdates() {
        presenter?.didReceiveWalletsState(hasUpdates: proxies.hasNotActive)
    }

    private func subscribeDApps() {
        let updateClosure: ([DataProviderChange<DAppList>]) -> Void = { [weak self] changes in
            if let result = changes.reduceToLastChange() {
                self?.presenter?.didReceive(dAppsResult: .success(result))
            } else {
                self?.presenter?.didReceive(dAppsResult: nil)
            }
        }

        let failureClosure: (Error) -> Void = { [weak self] error in
            self?.presenter?.didReceive(dAppsResult: .failure(error))
        }

        let options = DataProviderObserverOptions(alwaysNotifyOnRefresh: true, waitsInProgressSyncOnAdd: false)

        dAppProvider.addObserver(
            self,
            deliverOn: .main,
            executing: updateClosure,
            failing: failureClosure,
            options: options
        )
    }

    func addToFavorites(dApp: DApp) {
        let model = DAppFavorite(
            identifier: dApp.url.absoluteString,
            label: dApp.name,
            icon: dApp.icon?.absoluteString
        )

        let saveOperation = dAppsFavoriteRepository.saveOperation({ [model] }, { [] })

        operationQueue.addOperation(saveOperation)
    }

    func removeFromFavorites(dAppIdentifier: String) {
        let saveOperation = dAppsFavoriteRepository.saveOperation({ [] }, { [dAppIdentifier] })

        operationQueue.addOperation(saveOperation)
    }
}

extension DAppListInteractor: DAppListInteractorInputProtocol {
    func setup() {
        provideWallet()

        subscribeDApps()

        favoriteDAppsProvider = subscribeToFavoriteDApps(nil)

        phishingSyncService.setup()

        eventCenter.add(observer: self, dispatchIn: .main)

        proxyListSubscription = subscribeAllProxies()
        provideWalletUpdates()
    }

    func refresh() {
        dAppProvider.refresh()
    }
}

extension DAppListInteractor: EventVisitorProtocol {
    func processSelectedAccountChanged(event _: SelectedAccountChanged) {
        provideWallet()
    }
}

extension DAppListInteractor: DAppLocalStorageSubscriber, DAppLocalSubscriptionHandler {
    func handleFavoriteDApps(result: Result<[DataProviderChange<DAppFavorite>], Error>) {
        switch result {
        case let .success(changes):
            presenter?.didReceiveFavoriteDapp(changes: changes)
        case let .failure(error):
            logger.error("Unexpected favorites error: \(error)")
        }
    }
}

extension DAppListInteractor: ProxyListLocalStorageSubscriber, ProxyListLocalSubscriptionHandler {
    func handleAllProxies(result: Result<[DataProviderChange<ProxyAccountModel>], Error>) {
        switch result {
        case let .success(changes):
            proxies = proxies.applying(changes: changes)
            provideWalletUpdates()
        case let .failure(error):
            logger.error(error.localizedDescription)
        }
    }
}
