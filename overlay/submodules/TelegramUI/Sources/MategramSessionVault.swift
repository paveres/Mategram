import Foundation
import SwiftSignalKit
import TelegramCore
import MategramCore

private struct MategramStoredSession: Codable {
    let isTest: Bool
    let sortOrder: Int32
    let backup: AccountBackupData
}

private let mategramSessionsAccount = "sessions"

func mategramStoreSessions(_ records: [AccountRecord<TelegramAccountManagerTypes.Attribute>]) {
    guard MategramSettings.shared.bool(.sessionBackup) else {
        MategramSecureStore.remove(account: mategramSessionsAccount)
        return
    }
    var sessions: [MategramStoredSession] = []
    for record in records {
        var backup: AccountBackupData?
        var isTest = false
        var sortOrder: Int32 = 0
        var loggedOut = false
        for attribute in record.attributes {
            switch attribute {
            case let .backupData(value):
                backup = value.data
            case let .environment(value):
                isTest = value.environment == .test
            case let .sortOrder(value):
                sortOrder = value.order
            case .loggedOut:
                loggedOut = true
            default:
                break
            }
        }
        if let backup, !loggedOut {
            sessions.append(MategramStoredSession(isTest: isTest, sortOrder: sortOrder, backup: backup))
        }
    }
    if let data = try? JSONEncoder().encode(sessions) {
        MategramSecureStore.set(data, account: mategramSessionsAccount)
    }
}

func mategramRestoreSessions(accountManager: AccountManager<TelegramAccountManagerTypes>) {
    guard MategramSettings.shared.bool(.sessionBackup), let data = MategramSecureStore.get(account: mategramSessionsAccount), let sessions = try? JSONDecoder().decode([MategramStoredSession].self, from: data), !sessions.isEmpty else {
        return
    }
    let _ = accountManager.transaction { transaction -> Void in
        let active = transaction.getRecords().filter { record in
            return !record.attributes.contains(where: { attribute in
                if case .loggedOut = attribute {
                    return true
                }
                return false
            })
        }
        if !active.isEmpty {
            return
        }
        var firstId: AccountRecordId?
        for session in sessions.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let id = transaction.createRecord([
                .environment(AccountEnvironmentAttribute(environment: session.isTest ? .test : .production)),
                .sortOrder(AccountSortOrderAttribute(order: session.sortOrder)),
                .backupData(AccountBackupDataAttribute(data: session.backup))
            ])
            if firstId == nil {
                firstId = id
            }
        }
        if let firstId {
            transaction.setCurrentId(firstId)
            transaction.removeAuth()
        }
    }.startStandalone()
}
