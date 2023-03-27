import Foundation
import BigInt

protocol ParastakingLocalStorageHandler: AnyObject {
    func handleParastakingRound(
        result: Result<ParachainStaking.RoundInfo?, Error>,
        for chainId: ChainModel.Id
    )

    func handleParastakingDelegatorState(
        result: Result<ParachainStaking.Delegator?, Error>,
        for chainId: ChainModel.Id,
        accountId: AccountId
    )

    func handleParastakingCandidateMetadata(
        result: Result<ParachainStaking.CandidateMetadata?, Error>,
        for chainId: ChainModel.Id,
        accountId: AccountId
    )

    func handleParastakingScheduledRequests(
        result: Result<[ParachainStaking.DelegatorScheduledRequest]?, Error>,
        for chainId: ChainModel.Id,
        delegatorId: AccountId
    )

    func handleTotalReward(
        result: Result<TotalRewardItem, Error>,
        for address: AccountAddress,
        api: LocalChainExternalApi
    )
}

extension ParastakingLocalStorageHandler {
    func handleParastakingRound(
        result _: Result<ParachainStaking.RoundInfo?, Error>,
        for _: ChainModel.Id
    ) {}

    func handleParastakingDelegatorState(
        result _: Result<ParachainStaking.Delegator?, Error>,
        for _: ChainModel.Id,
        accountId _: AccountId
    ) {}

    func handleParastakingScheduledRequests(
        result _: Result<[ParachainStaking.DelegatorScheduledRequest]?, Error>,
        for _: ChainModel.Id,
        delegatorId _: AccountId
    ) {}

    func handleTotalReward(
        result _: Result<TotalRewardItem, Error>,
        for _: AccountAddress,
        api _: LocalChainExternalApi
    ) {}

    func handleParastakingCandidateMetadata(
        result _: Result<ParachainStaking.CandidateMetadata?, Error>,
        for _: ChainModel.Id,
        accountId _: AccountId
    ) {}
}
