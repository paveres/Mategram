import Foundation
import UIKit
import Display
import AccountContext
import TelegramPresentationData
import TelegramCore
import SwiftSignalKit
import AsyncDisplayKit
import UndoUI
import MategramCore

private func mategramCopy(context: AccountContext, presentationData: PresentationData, text: String, message: String) {
    UIPasteboard.general.string = text
    context.sharedContext.mainWindow?.present(UndoOverlayController(presentationData: presentationData, content: .copy(text: message), elevatedLayout: false, animateInAsReplacement: false, action: { _ in
        return false
    }), on: .root)
}

private func mategramDataCenter(peer: EnginePeer) -> Int? {
    guard let representation = peer.smallProfileImage else {
        return nil
    }
    if let resource = representation.resource as? CloudPeerPhotoSizeMediaResource {
        return resource.datacenterId
    }
    return nil
}

func mategramPeerInfoItems(
    data: PeerInfoScreenData,
    context: AccountContext,
    presentationData: PresentationData,
    interaction: PeerInfoInteraction
) -> [PeerInfoScreenItem] {
    guard let peer = data.peer else {
        return []
    }
    let language = MategramLanguage(code: presentationData.strings.baseLanguageCode)
    let settings = MategramSettings.shared
    var result: [PeerInfoScreenItem] = []

    let rawId: Int64 = peer.id.id._internalGetInt64Value()
    var idText = String(rawId)
    if peer.id.namespace == Namespaces.Peer.CloudChannel {
        idText = "-100" + idText
    } else if peer.id.namespace == Namespaces.Peer.CloudGroup {
        idText = "-" + idText
    }

    if settings.bool(.showProfileId) {
        let copyMessage = MategramText.copiedId.string(language)
        result.append(PeerInfoScreenLabeledValueItem(id: 9001, label: MategramText.rowId.string(language), text: idText, textColor: .primary, action: { _, _ in
            mategramCopy(context: context, presentationData: presentationData, text: idText, message: copyMessage)
        }, longTapAction: nil, requestLayout: { _ in
        }))
    }

    if settings.bool(.showDataCenter) {
        var dataCenterText: String?
        if let number = mategramDataCenter(peer: peer) {
            dataCenterText = "DC\(number)"
        }
        var countryText: String?
        if let cachedData = data.cachedData as? CachedUserData, let phoneCountry = cachedData.peerStatusSettings?.phoneCountry, !phoneCountry.isEmpty {
            if phoneCountry == "FT" {
                countryText = MategramText.anonymousNumber.string(language)
            } else if let name = Locale(identifier: language == .russian ? "ru_RU" : "en_US").localizedString(forRegionCode: phoneCountry) {
                countryText = name
            }
        }
        var parts: [String] = []
        if let dataCenterText {
            parts.append(dataCenterText)
        }
        if let countryText {
            parts.append(countryText)
        }
        if !parts.isEmpty {
            let value = parts.joined(separator: " · ")
            let copyMessage = MategramText.copiedValue.string(language)
            result.append(PeerInfoScreenLabeledValueItem(id: 9002, label: MategramText.rowDataCenter.string(language), text: value, textColor: .primary, action: { _, _ in
                mategramCopy(context: context, presentationData: presentationData, text: value, message: copyMessage)
            }, longTapAction: nil, requestLayout: { _ in
            }))
        }
    }

    if case let .user(user) = peer, peer.id != context.account.peerId {
        if settings.bool(.showMutualContact), user.flags.contains(.mutualContact) {
            result.append(PeerInfoScreenLabeledValueItem(id: 9003, label: MategramText.rowContacts.string(language), text: MategramText.rowContactsMutual.string(language), textColor: .primary, action: nil, longTapAction: nil, requestLayout: { _ in
            }))
        }

        if settings.bool(.showRegistrationDate) {
            var value: String?
            if let cachedData = data.cachedData as? CachedUserData, let registration = cachedData.peerStatusSettings?.registrationDate {
                value = MategramRegDate.text(telegramMonth: registration, languageCode: presentationData.strings.baseLanguageCode)
            }
            if value == nil {
                let now = Int32(clamping: Int64(Date().timeIntervalSince1970))
                if let estimate = MategramRegDate.estimate(userId: rawId, now: now) {
                    value = MategramRegDate.text(estimate: estimate, languageCode: presentationData.strings.baseLanguageCode)
                }
            }
            if let value {
                let copyMessage = MategramText.copiedValue.string(language)
                result.append(PeerInfoScreenLabeledValueItem(id: 9004, label: MategramText.rowRegistration.string(language), text: value, textColor: .primary, action: { _, _ in
                    mategramCopy(context: context, presentationData: presentationData, text: value, message: copyMessage)
                }, longTapAction: nil, requestLayout: { _ in
                }))
            }
        }
    }

    if settings.bool(.showCreationDate) {
        var creationDate: Int32?
        if case let .legacyGroup(group) = peer {
            creationDate = group.creationDate
        } else if case let .channel(channel) = peer, channel.flags.contains(.isCreator) {
            creationDate = channel.creationDate
        }
        if let creationDate, creationDate > 0 {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: language == .russian ? "ru_RU" : "en_US")
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            let value = formatter.string(from: Date(timeIntervalSince1970: Double(creationDate)))
            let label = language == .russian ? "создано" : "created"
            result.append(PeerInfoScreenLabeledValueItem(id: 9006, label: label, text: value, textColor: .primary, action: nil, longTapAction: nil, requestLayout: { _ in
            }))
        }
    }

    if MategramGhost.showsServerReadAction, peer.id != context.account.peerId, MategramGhost.holdsReadReceipt(peer: peer.id.toInt64()) {
        let readTitle = language == .russian ? "Прочитать на сервере" : "Mark as read on server"
        let readDone = language == .russian ? "Чат отмечен прочитанным у собеседника" : "The chat is marked as read for the other side"
        let peerId = peer.id
        result.append(PeerInfoScreenActionItem(id: 9007, text: readTitle, action: {
            let _ = mategramPushReadStateNow(account: context.account, peerId: peerId).start(completed: {
                Queue.mainQueue().async {
                    context.sharedContext.mainWindow?.present(UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: readDone, timeout: nil, customUndoText: nil), elevatedLayout: false, animateInAsReplacement: false, action: { _ in
                        return false
                    }), on: .root)
                }
            })
        }))
    }

    if settings.bool(.ghostMode), peer.id != context.account.peerId {
        let peerKey = peer.id.toInt64()
        let ghostTitle = language == .russian ? "Режим призрака в этом чате" : "Ghost mode in this chat"
        result.append(PeerInfoScreenSwitchItem(id: 9005, text: ghostTitle, value: !MategramGhost.isException(peer: peerKey), toggled: { value in
            MategramGhost.setException(peer: peerKey, !value)
        }))
    }

    return result
}
