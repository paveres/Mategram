import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import ContextUI
import UndoUI
import MategramCore

func mategramChatGhostItems(context: AccountContext, peer: EnginePeer, presentationData: PresentationData) -> [ContextMenuItem] {
    let settings = MategramSettings.shared
    if peer.id == context.account.peerId || !settings.bool(.ghostMode) || !settings.bool(.ghostChatButtons) {
        return []
    }
    let isRussian = presentationData.strings.baseLanguageCode.hasPrefix("ru")
    let peerKey = peer.id.toInt64()
    let isOn = !MategramGhost.isException(peer: peerKey)
    var items: [ContextMenuItem] = [.separator]
    items.append(.action(ContextMenuActionItem(text: isRussian ? "Призрак в этом чате" : "Ghost in this chat", icon: { theme in
        return generateTintedImage(image: UIImage(bundleImageName: isOn ? "Chat/Context Menu/EyeLocked" : "Chat/Context Menu/Eye"), color: theme.contextMenu.primaryColor)
    }, action: { _, f in
        f(.default)
        MategramGhost.setException(peer: peerKey, isOn)
        let text = isOn ? (isRussian ? "Призрак выключен в этом чате" : "Ghost mode is off in this chat") : (isRussian ? "Призрак включён в этом чате" : "Ghost mode is on in this chat")
        context.sharedContext.mainWindow?.present(UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: text, timeout: nil, customUndoText: nil), elevatedLayout: false, animateInAsReplacement: false, action: { _ in
            return false
        }), on: .root)
    })))
    if MategramGhost.showsServerReadAction, MategramGhost.holdsReadReceipt(peer: peerKey) {
        let peerId = peer.id
        items.append(.action(ContextMenuActionItem(text: isRussian ? "Прочитать на сервере" : "Mark as read on server", icon: { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Read"), color: theme.contextMenu.primaryColor)
        }, action: { _, f in
            f(.default)
            let doneText = isRussian ? "Чат отмечен прочитанным у собеседника" : "The chat is marked as read for the other side"
            let _ = mategramPushReadStateNow(account: context.account, peerId: peerId).startStandalone(completed: {
                Queue.mainQueue().async {
                    context.sharedContext.mainWindow?.present(UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: doneText, timeout: nil, customUndoText: nil), elevatedLayout: false, animateInAsReplacement: false, action: { _ in
                        return false
                    }), on: .root)
                }
            })
        })))
    }
    return items
}
