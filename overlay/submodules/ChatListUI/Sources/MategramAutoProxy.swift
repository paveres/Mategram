import Foundation
import SwiftSignalKit
import TelegramCore
import AccountContext
import MategramCore

private final class MategramAutoProxy {
    static var current: MategramAutoProxy?

    let accountId: Int64
    private let disposable = MetaDisposable()
    private var connectingSince: Double?
    private var lastSwitch: Double = 0.0

    init(context: AccountContext) {
        self.accountId = context.account.peerId.toInt64()
        let accountManager = context.sharedContext.accountManager
        self.disposable.set((context.account.network.connectionStatus
        |> deliverOnMainQueue).startStrict(next: { [weak self] status in
            guard let self else {
                return
            }
            switch status {
            case .connecting:
                if self.connectingSince == nil {
                    self.connectingSince = CFAbsoluteTimeGetCurrent()
                    let delay = Double(MategramSettings.shared.value(.autoProxyDelay))
                    Queue.mainQueue().after(delay, { [weak self] in
                        self?.check(accountManager: accountManager, delay: delay)
                    })
                }
            default:
                self.connectingSince = nil
            }
        }))
    }

    deinit {
        self.disposable.dispose()
    }

    private func check(accountManager: AccountManager<TelegramAccountManagerTypes>, delay: Double) {
        guard MategramSettings.shared.bool(.autoProxy), let since = self.connectingSince else {
            return
        }
        let now = CFAbsoluteTimeGetCurrent()
        if now - since < delay - 0.5 || now - self.lastSwitch < delay {
            return
        }
        self.lastSwitch = now
        self.connectingSince = now
        let _ = updateProxySettingsInteractively(accountManager: accountManager, { settings in
            var settings = settings
            if settings.servers.isEmpty {
                return settings
            }
            if !settings.enabled {
                settings.enabled = true
                if settings.activeServer == nil {
                    settings.activeServer = settings.servers.first
                }
            } else if let active = settings.activeServer, let index = settings.servers.firstIndex(of: active) {
                settings.activeServer = settings.servers[(index + 1) % settings.servers.count]
            } else {
                settings.activeServer = settings.servers.first
            }
            return settings
        }).startStandalone()
        Queue.mainQueue().after(delay, { [weak self] in
            self?.check(accountManager: accountManager, delay: delay)
        })
    }
}

func mategramStartAutoProxy(context: AccountContext) {
    let accountId = context.account.peerId.toInt64()
    if let current = MategramAutoProxy.current, current.accountId == accountId {
        return
    }
    MategramAutoProxy.current = MategramAutoProxy(context: context)
}
