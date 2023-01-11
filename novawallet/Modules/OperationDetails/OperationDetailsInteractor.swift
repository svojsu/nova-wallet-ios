import UIKit
import CommonWallet
import BigInt
import RobinHood

enum OperationDetailsInteractorError: Error {
    case unsupportTxType
}

final class OperationDetailsInteractor: AccountFetching {
    weak var presenter: OperationDetailsInteractorOutputProtocol?

    let transaction: TransactionHistoryItem
    let chainAsset: ChainAsset

    var chain: ChainModel { chainAsset.chain }

    let walletRepository: AnyDataProviderRepository<MetaAccountModel>
    let transactionLocalSubscriptionFactory: TransactionLocalSubscriptionFactoryProtocol
    let operationQueue: OperationQueue
    let wallet: MetaAccountModel

    private var accountAddress: AccountAddress? {
        wallet.fetch(for: chain.accountRequest())?.toAddress()
    }

    private var transactionProvider: StreamableProvider<TransactionHistoryItem>?

    init(
        transaction: TransactionHistoryItem,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        walletRepository: AnyDataProviderRepository<MetaAccountModel>,
        transactionLocalSubscriptionFactory: TransactionLocalSubscriptionFactoryProtocol,
        operationQueue: OperationQueue
    ) {
        self.transaction = transaction
        self.chainAsset = chainAsset
        self.wallet = wallet
        self.walletRepository = walletRepository
        self.transactionLocalSubscriptionFactory = transactionLocalSubscriptionFactory
        self.operationQueue = operationQueue
    }

    private func extractStatus(
        overridingBy newStatus: OperationDetailsModel.Status?
    ) -> OperationDetailsModel.Status {
        if let newStatus = newStatus {
            return newStatus
        } else {
            switch transaction.status {
            case .success:
                return .completed
            case .pending:
                return .pending
            case .failed:
                return .failed
            }
        }
    }

    private func extractSlashOperationData(
        _ completion: @escaping (OperationDetailsModel.OperationData?) -> Void
    ) {
        let context = try? transaction.call.map {
            try JSONDecoder().decode(HistoryRewardContext.self, from: $0)
        }

        let eventId = getEventId(from: context) ?? transaction.txHash

        let precision = Int16(bitPattern: chainAsset.asset.precision)

        let amount = transaction.amountInPlankIntOrZero

        if let validatorId = try? transaction.sender.toAccountId() {
            _ = fetchDisplayAddress(
                for: [validatorId],
                chain: chain,
                repository: walletRepository,
                operationQueue: operationQueue
            ) { result in
                switch result {
                case let .success(addresses):
                    let model = OperationSlashModel(
                        eventId: eventId,
                        amount: amount,
                        validator: addresses.first,
                        era: context?.era
                    )

                    completion(.slash(model))
                case .failure:
                    completion(nil)
                }
            }
        } else {
            let model = OperationSlashModel(
                eventId: eventId,
                amount: amount,
                validator: nil,
                era: context?.era
            )

            completion(.slash(model))
        }
    }

    private func extractRewardOperationData(
        _ completion: @escaping (OperationDetailsModel.OperationData?) -> Void
    ) {
        let context = try? transaction.call.map {
            try JSONDecoder().decode(HistoryRewardContext.self, from: $0)
        }

        let eventId = getEventId(from: context) ?? transaction.txHash

        let precision = Int16(bitPattern: chainAsset.asset.precision)
        let amount = transaction.amountInPlankIntOrZero

        if let validatorId = try? transaction.sender.toAccountId() {
            _ = fetchDisplayAddress(
                for: [validatorId],
                chain: chain,
                repository: walletRepository,
                operationQueue: operationQueue
            ) { result in
                switch result {
                case let .success(addresses):
                    let model = OperationRewardModel(
                        eventId: eventId,
                        amount: amount,
                        validator: addresses.first,
                        era: context?.era
                    )

                    completion(.reward(model))
                case .failure:
                    completion(nil)
                }
            }
        } else {
            let model = OperationRewardModel(
                eventId: eventId,
                amount: amount,
                validator: nil,
                era: context?.era
            )

            completion(.reward(model))
        }
    }

    private func getEventId(from context: HistoryRewardContext?) -> String? {
        guard let eventId = context?.eventId else {
            return nil
        }
        return !eventId.isEmpty ? eventId : nil
    }

    private func extractExtrinsicOperationData(
        newFee: BigUInt?,
        _ completion: @escaping (OperationDetailsModel.OperationData?) -> Void
    ) {
        guard let accountAddress = accountAddress else {
            completion(nil)
            return
        }

        let precision = Int16(bitPattern: chainAsset.asset.precision)
        let fee =  newFee ?? transaction.amountInPlankIntOrZero

        let currentDisplayAddress = DisplayAddress(
            address: accountAddress,
            username: wallet.name
        )

        let model = OperationExtrinsicModel(
            txHash: transaction.identifier,
            call: transaction.callPath.callName,
            module: transaction.callPath.moduleName,
            sender: currentDisplayAddress,
            fee: fee
        )

        completion(.extrinsic(model))
    }

    private func extractTransferOperationData(
        newFee: BigUInt?,
        _ completion: @escaping (OperationDetailsModel.OperationData?) -> Void
    ) {
        guard let accountAddress = accountAddress else {
            completion(nil)
            return
        }
        let peerAddress = (transaction.sender == accountAddress ? transaction.receiver : transaction.sender) ?? transaction.sender
        let accountId = try? peerAddress.toAccountId(using: chain.chainFormat)
        let peerId = accountId?.toHex() ?? peerAddress

        guard let peerId = try? Data(hexString: peerId) else {
            completion(nil)
            return
        }

        let isOutgoing = transaction.type(for: accountAddress) == .outgoing

        let precision = Int16(bitPattern: chainAsset.asset.precision)

        let amount = transaction.amountInPlankIntOrZero

        let fee = newFee ?? transaction.feeInPlankIntOrZero

        let currentDisplayAddress = DisplayAddress(
            address: accountAddress,
            username: wallet.name
        )

        let txId = transaction.identifier

        _ = fetchDisplayAddress(
            for: [peerId],
            chain: chain,
            repository: walletRepository,
            operationQueue: operationQueue
        ) { result in
            switch result {
            case let .success(otherDisplayAddresses):
                if let otherDisplayAddress = otherDisplayAddresses.first {
                    let model = OperationTransferModel(
                        txHash: txId,
                        amount: amount,
                        fee: fee,
                        sender: isOutgoing ? currentDisplayAddress : otherDisplayAddress,
                        receiver: isOutgoing ? otherDisplayAddress : currentDisplayAddress,
                        outgoing: isOutgoing
                    )

                    completion(.transfer(model))
                } else {
                    completion(nil)
                }

            case .failure:
                completion(nil)
            }
        }
    }

    private func extractOperationData(
        replacingIfExists newFee: BigUInt?,
        _ completion: @escaping (OperationDetailsModel.OperationData?) -> Void
    ) {
        guard let accountAddress = accountAddress else {
            completion(nil)
            return
        }
        switch transaction.type(for: accountAddress) {
        case .incoming, .outgoing:
            extractTransferOperationData(newFee: newFee, completion)
        case .reward:
            extractRewardOperationData(completion)
        case .slash:
            extractSlashOperationData(completion)
        case .extrinsic:
            extractExtrinsicOperationData(newFee: newFee, completion)
        case .none:
            completion(nil)
        }
    }

    private func provideModel(
        for operationData: OperationDetailsModel.OperationData,
        overridingBy newStatus: OperationDetailsModel.Status?
    ) {
        let time = Date(timeIntervalSince1970: TimeInterval(transaction.timestamp))
        let status = extractStatus(overridingBy: newStatus)

        let details = OperationDetailsModel(
            time: time,
            status: status,
            operation: operationData
        )

        presenter?.didReceiveDetails(result: .success(details))
    }

    private func provideModel(
        overridingBy newStatus: OperationDetailsModel.Status?,
        newFee: BigUInt?
    ) {
        extractOperationData(replacingIfExists: newFee) { [weak self] operationData in
            if let operationData = operationData {
                self?.provideModel(for: operationData, overridingBy: newStatus)
            } else {
                let error = OperationDetailsInteractorError.unsupportTxType
                self?.presenter?.didReceiveDetails(result: .failure(error))
            }
        }
    }
}

extension OperationDetailsInteractor: OperationDetailsInteractorInputProtocol {
    func setup() {
        provideModel(overridingBy: nil, newFee: nil)
        transactionProvider = subscribeToTransaction(for: transaction.identifier, chainId: chain.chainId)
    }
}

extension OperationDetailsInteractor: TransactionLocalStorageSubscriber,
    TransactionLocalSubscriptionHandler {
    func handleTransactions(result: Result<[DataProviderChange<TransactionHistoryItem>], Error>) {
        switch result {
        case let .success(changes):
            if let transaction = changes.reduceToLastChange() {
                let newFee = transaction.fee.flatMap { BigUInt($0) }
                switch transaction.status {
                case .success:
                    provideModel(overridingBy: .completed, newFee: newFee)
                case .failed:
                    provideModel(overridingBy: .failed, newFee: newFee)
                case .pending:
                    provideModel(overridingBy: .pending, newFee: newFee)
                }
            }
        case let .failure(error):
            presenter?.didReceiveDetails(result: .failure(error))
        }
    }
}
