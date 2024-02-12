import Foundation
import RobinHood
import BigInt

protocol HydraQuoteFactoryProtocol {
    func quote(for args: AssetConversion.QuoteArgs) -> CompoundOperationWrapper<AssetConversion.Quote>
}

final class HydraQuoteFactory {
    let flowState: HydraFlowState

    init(flowState: HydraFlowState) {
        self.flowState = flowState
    }

    private func createRouteComponentQuoteWrapper(
        for component: HydraDx.SwapRoute<HydraDx.AssetId>.Component,
        lastWrapper: CompoundOperationWrapper<BigUInt>,
        direction: AssetConversion.Direction,
        flowState: HydraFlowState
    ) -> CompoundOperationWrapper<BigUInt> {
        OperationCombiningService.compoundNonOptionalWrapper(
            operationManager: OperationManager(operationQueue: flowState.operationQueue)
        ) {
            let amount = try lastWrapper.targetOperation.extractNoCancellableResultData()

            switch component.type {
            case .omnipool:
                let omnipoolState = flowState.getOmnipoolFlowState()
                let quoteFactory = HydraOmnipoolQuoteFactory(flowState: omnipoolState)

                return quoteFactory.quote(
                    for: .init(
                        assetIn: component.assetIn,
                        assetOut: component.assetOut,
                        amount: amount,
                        direction: direction
                    )
                )
            case let .stableswap(poolAsset):
                let stableswapState = flowState.getStableswapFlowState()
                let quoteFactory = HydraStableswapQuoteFactory(flowState: stableswapState)

                return quoteFactory.quote(
                    for: .init(
                        assetIn: component.assetIn,
                        assetOut: component.assetOut,
                        poolAsset: poolAsset,
                        amount: amount,
                        direction: direction
                    )
                )
            }
        }
    }

    private func createQuoteWrapper(
        route: HydraDx.SwapRoute<HydraDx.AssetId>,
        args: AssetConversion.QuoteArgs
    ) -> CompoundOperationWrapper<AssetConversion.Quote> {
        let components: [HydraDx.SwapRoute<HydraDx.AssetId>.Component]

        switch args.direction {
        case .sell:
            components = route.components
        case .buy:
            components = Array(route.components.reversed())
        }

        let quoteWrapper: CompoundOperationWrapper<BigUInt> = components.reduce(
            CompoundOperationWrapper.createWithResult(args.amount)
        ) { lastWrapper, component in
            let nextWrapper = createRouteComponentQuoteWrapper(
                for: component,
                lastWrapper: lastWrapper,
                direction: args.direction,
                flowState: flowState
            )

            nextWrapper.addDependency(operations: [lastWrapper.targetOperation])

            let dependecies = lastWrapper.allOperations + nextWrapper.dependencies

            return CompoundOperationWrapper(targetOperation: nextWrapper.targetOperation, dependencies: dependecies)
        }

        let mapOperation = ClosureOperation<AssetConversion.Quote> {
            let amount = try quoteWrapper.targetOperation.extractNoCancellableResultData()

            let context = try JsonStringify.jsonString(from: route)
            return .init(args: args, amount: amount, context: context)
        }

        mapOperation.addDependency(quoteWrapper.targetOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: quoteWrapper.allOperations)
    }

    private func createQuoteWrapper(
        dependingOn routesOperation: BaseOperation<[HydraDx.SwapRoute<HydraDx.AssetId>]>,
        args: AssetConversion.QuoteArgs
    ) -> CompoundOperationWrapper<AssetConversion.Quote> {
        let quoteOperation = OperationCombiningService(
            operationManager: OperationManager(operationQueue: flowState.operationQueue)
        ) {
            let routes = try routesOperation.extractNoCancellableResultData()

            return routes.map { self.createQuoteWrapper(route: $0, args: args) }
        }.longrunOperation()

        let mapOperation = ClosureOperation<AssetConversion.Quote> {
            let quotes = try quoteOperation.extractNoCancellableResultData()

            switch args.direction {
            case .sell:
                guard let maxSellQuote = quotes.max(by: { $0.amountOut < $1.amountOut }) else {
                    throw AssetConversionOperationError.quoteCalcFailed
                }

                return maxSellQuote
            case .buy:
                guard let minBuyQuote = quotes.min(by: { $0.amountIn < $1.amountIn }) else {
                    throw AssetConversionOperationError.quoteCalcFailed
                }

                return minBuyQuote
            }
        }

        mapOperation.addDependency(quoteOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: [quoteOperation])
    }
}

extension HydraQuoteFactory: HydraQuoteFactoryProtocol {
    func quote(for args: AssetConversion.QuoteArgs) -> CompoundOperationWrapper<AssetConversion.Quote> {
        flowState.resetServicesIfNotMatchingPair(
            .init(assetIn: args.assetIn, assetOut: args.assetOut)
        )

        let routesFactory = flowState.getRoutesFactory()

        let swapPair = HydraDx.LocalSwapPair(assetIn: args.assetIn, assetOut: args.assetOut)
        let routesWrapper = routesFactory.createRoutesWrapper(for: swapPair)

        let quoteWrapper = createQuoteWrapper(
            dependingOn: routesWrapper.targetOperation,
            args: args
        )

        quoteWrapper.addDependency(wrapper: routesWrapper)

        return quoteWrapper.insertingHead(operations: routesWrapper.allOperations)
    }
}
