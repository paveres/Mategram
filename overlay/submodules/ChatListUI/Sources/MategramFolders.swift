import Foundation
import MategramCore
import ChatListFilterTabContainerNode

private let mategramFolderKey = "mategram.lastFolder"

func mategramStoreFolder(_ id: ChatListFilterTabEntryId) {
    guard MategramSettings.shared.bool(.rememberFolder) else {
        return
    }
    switch id {
    case .all:
        UserDefaults.standard.set(-1, forKey: mategramFolderKey)
    case let .filter(value):
        UserDefaults.standard.set(Int(value), forKey: mategramFolderKey)
    }
}

func mategramVisibleFolders(_ items: [ChatListFilterTabEntry]) -> [ChatListFilterTabEntry] {
    guard MategramSettings.shared.bool(.hideAllChatsTab) else {
        return items
    }
    let hasFolders = items.contains(where: { entry in
        if case .filter = entry.id {
            return true
        }
        return false
    })
    if !hasFolders {
        return items
    }
    return items.filter { $0.id != .all }
}

func mategramInitialFolder(_ fallback: ChatListFilterTabEntryId, _ items: [ChatListFilterTabEntry]) -> ChatListFilterTabEntryId {
    if MategramSettings.shared.bool(.rememberFolder), let raw = UserDefaults.standard.object(forKey: mategramFolderKey) as? Int {
        let stored: ChatListFilterTabEntryId = raw < 0 ? .all : .filter(Int32(raw))
        if items.contains(where: { $0.id == stored }) {
            return stored
        }
    }
    if items.isEmpty || items.contains(where: { $0.id == fallback }) {
        return fallback
    }
    return items[0].id
}
