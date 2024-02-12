import XCTest
@testable import novawallet

final class HydraQuoteTests: XCTestCase {
    
    func testDotUSDTSell() {
        do {
            let quote = try fetchQuote(
                for: .init(
                    assetIn: .init(chainId: KnowChainId.hydra, assetId: 1),
                    assetOut: .init(chainId: KnowChainId.hydra, assetId: 9),
                    amount: 10_000_000_000,
                    direction: .sell
                )
            )
            
            Logger.shared.info("Quote: \(quote)")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    

    func fetchQuote(for args: AssetConversion.QuoteArgs) throws -> AssetConversion.Quote {
        let storageFacade = SubstrateStorageTestFacade()
        let chainRegistry = ChainRegistryFacade.setupForIntegrationTest(with: storageFacade)
        
        let wallet = AccountGenerator.generateMetaAccount()
        let chainId = args.assetIn.chainId
        
        guard
            let chain = chainRegistry.getChain(for: chainId),
            let connection = chainRegistry.getConnection(for: chainId),
            let runtimeService = chainRegistry.getRuntimeProvider(for: chainId),
            let account = wallet.fetch(for: chain.accountRequest()) else {
            throw ChainRegistryError.noChain(chainId)
        }
        
        let operationQueue = OperationQueue()
        
        let flowState = HydraFlowState(
            account: account,
            chain: chain,
            connection: connection,
            runtimeProvider: runtimeService,
            userStorageFacade: UserDataStorageTestFacade(),
            operationQueue: operationQueue
        )
        
        let quoteFactory = HydraQuoteFactory(flowState: flowState)
        
        let quoteWrapper = quoteFactory.quote(for: args)
        
        operationQueue.addOperations(quoteWrapper.allOperations, waitUntilFinished: true)
        
        return try quoteWrapper.targetOperation.extractNoCancellableResultData()
    }
}
