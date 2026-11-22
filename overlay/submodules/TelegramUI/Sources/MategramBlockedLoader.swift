import Foundation
import SwiftSignalKit
import TelegramCore
import AccountContext
import MategramCore

private final class MategramBlockedStore {
    static var context: BlockedPeersContext?
    static var disposable: Disposable?
    static var accountId: Int64?
}

func mategramLoadBlocked(context: AccountContext) {
    guard MategramSettings.shared.bool(.hideBlockedMessages) else {
        return
    }
    let accountId = context.account.peerId.toInt64()
    if MategramBlockedStore.accountId == accountId, MategramBlockedStore.context != nil {
        return
    }
    MategramBlockedStore.disposable?.dispose()
    let blocked = BlockedPeersContext(account: context.account, subject: .blocked)
    MategramBlockedStore.context = blocked
    MategramBlockedStore.accountId = accountId
    MategramBlockedStore.disposable = (blocked.state
    |> deliverOnMainQueue).startStrict(next: { [weak blocked] state in
        MategramBlocked.ids = Set(state.peers.map { $0.peerId.toInt64() })
        if state.canLoadMore && !state.isLoadingMore {
            Queue.mainQueue().async {
                blocked?.loadMore()
            }
        }
    })
}
